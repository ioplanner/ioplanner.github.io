// Osobný diár → Kalendár Apple (odoberaný kalendár .ics)
//
// Supabase: Edge Functions → Deploy a new function → Via Editor
//   názov funkcie: kalendar
//   sem vlož celý tento súbor → Deploy
//   potom v nastaveniach funkcie VYPNI "Verify JWT" (Kalendár Apple sa neprihlasuje,
//   prístup chráni tajný kľúč v adrese).
//
// Adresa kalendára: https://<projekt>.supabase.co/functions/v1/kalendar?t=<tajný kľúč>
// Tajný kľúč vytvára a ukazuje diár (tlačidlo „Kalendár Apple“).

const TZID = "Europe/Bratislava";
const SITE = "https://ioplanner.github.io/";
const STATUS = { todo: "Naplánované", doing: "Prebieha", done: "Hotovo" };
const KINDS = { ponuka: "Cenová ponuka", faktura: "Faktúra", ine: "Iné" };

const VTIMEZONE = [
  "BEGIN:VTIMEZONE",
  "TZID:" + TZID,
  "BEGIN:DAYLIGHT",
  "TZOFFSETFROM:+0100",
  "TZOFFSETTO:+0200",
  "TZNAME:CEST",
  "DTSTART:19700329T020000",
  "RRULE:FREQ=YEARLY;BYMONTH=3;BYDAY=-1SU",
  "END:DAYLIGHT",
  "BEGIN:STANDARD",
  "TZOFFSETFROM:+0200",
  "TZOFFSETTO:+0100",
  "TZNAME:CET",
  "DTSTART:19701025T030000",
  "RRULE:FREQ=YEARLY;BYMONTH=10;BYDAY=-1SU",
  "END:STANDARD",
  "END:VTIMEZONE",
];

const pad = (n) => String(n).padStart(2, "0");

// Text values: escape backslash, semicolon, comma and newlines (RFC 5545 §3.3.11)
function esc(s) {
  return String(s ?? "")
    .replace(/\\/g, "\\\\")
    .replace(/;/g, "\\;")
    .replace(/,/g, "\\,")
    .replace(/\r\n|\r|\n/g, "\\n");
}

// Fold lines longer than 75 octets, never splitting a UTF-8 character
const enc = new TextEncoder();
function fold(line) {
  if (enc.encode(line).length <= 75) return line;
  const out = [];
  let cur = "", bytes = 0;
  for (const ch of line) {
    const b = enc.encode(ch).length;
    const limit = out.length === 0 ? 75 : 74; // continuation lines start with a space
    if (bytes + b > limit) { out.push(cur); cur = ""; bytes = 0; }
    cur += ch; bytes += b;
  }
  out.push(cur);
  return out.join("\r\n ");
}

const ymd = (d) => d.getUTCFullYear() + pad(d.getUTCMonth() + 1) + pad(d.getUTCDate());
const hms = (d) => pad(d.getUTCHours()) + pad(d.getUTCMinutes()) + "00";
const utcStamp = (iso) => {
  const d = iso ? new Date(iso) : new Date();
  return ymd(d) + "T" + pad(d.getUTCHours()) + pad(d.getUTCMinutes()) + pad(d.getUTCSeconds()) + "Z";
};

// Local wall-clock times are handled as "floating" UTC dates for arithmetic only
function wall(dateStr, timeStr) {
  const [y, m, d] = dateStr.split("-").map(Number);
  const [hh, mm] = (timeStr || "00:00").split(":").map(Number);
  return new Date(Date.UTC(y, m - 1, d, hh || 0, mm || 0));
}

export function buildEvent(ev) {
  const lines = ["BEGIN:VEVENT", "UID:" + ev.id + "@ioplanner"];
  lines.push("DTSTAMP:" + utcStamp(ev.updated_at));
  if (ev.updated_at) lines.push("LAST-MODIFIED:" + utcStamp(ev.updated_at));

  const start = (ev.start_time || "").slice(0, 5);
  const endT = (ev.end_time || "").slice(0, 5);
  if (start) {
    const s = wall(ev.event_date, start);
    let e = endT ? wall(ev.event_date, endT) : new Date(s.getTime() + 3600e3);
    if (e <= s) e = new Date(e.getTime() + 86400e3); // ends after midnight
    lines.push("DTSTART;TZID=" + TZID + ":" + ymd(s) + "T" + hms(s));
    lines.push("DTEND;TZID=" + TZID + ":" + ymd(e) + "T" + hms(e));
  } else {
    const s = wall(ev.event_date);
    lines.push("DTSTART;VALUE=DATE:" + ymd(s));
    lines.push("DTEND;VALUE=DATE:" + ymd(new Date(s.getTime() + 86400e3)));
  }

  const done = ev.status === "done";
  lines.push("SUMMARY:" + esc((done ? "✓ " : "") + ev.title));

  const parts = ["Stav: " + (STATUS[ev.status] || STATUS.todo)];
  if (ev.notes && ev.notes.trim()) parts.push(ev.notes.trim());
  const checklist = Array.isArray(ev.checklist) ? ev.checklist : [];
  if (checklist.length) {
    parts.push("Checklist:\n" + checklist.map((c) => (c.done ? "☑ " : "☐ ") + c.text).join("\n"));
  }
  const files = Array.isArray(ev.attachments) ? ev.attachments : [];
  if (files.length) {
    parts.push("Prílohy (otvoríš v diári):\n" + files.map((a) => "• " + (KINDS[a.kind] || KINDS.ine) + ": " + a.name).join("\n"));
  }
  lines.push("DESCRIPTION:" + esc(parts.join("\n\n")));
  lines.push("CATEGORIES:" + esc(STATUS[ev.status] || STATUS.todo));
  lines.push("URL:" + SITE);
  lines.push("TRANSP:" + (start ? "OPAQUE" : "TRANSPARENT"));
  lines.push("END:VEVENT");
  return lines;
}

export function buildCalendar(events) {
  const lines = [
    "BEGIN:VCALENDAR",
    "VERSION:2.0",
    "PRODID:-//ioPlanner//Osobny diar//SK",
    "CALSCALE:GREGORIAN",
    "METHOD:PUBLISH",
    "X-WR-CALNAME:Osobný diár",
    "X-WR-TIMEZONE:" + TZID,
    "X-APPLE-CALENDAR-COLOR:#2547C4",
    "REFRESH-INTERVAL;VALUE=DURATION:PT15M",
    "X-PUBLISHED-TTL:PT15M",
    ...VTIMEZONE,
  ];
  for (const ev of events) lines.push(...buildEvent(ev));
  lines.push("END:VCALENDAR");
  return lines.map(fold).join("\r\n") + "\r\n";
}

const text = (body, status) =>
  new Response(body, { status, headers: { "Content-Type": "text/plain; charset=utf-8", "Cache-Control": "no-store" } });

// Server key: the legacy service_role key, or one of the newer secret keys
function serverKey() {
  const legacy = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
  if (legacy) return legacy;
  const raw = Deno.env.get("SUPABASE_SECRET_KEYS") || Deno.env.get("SUPABASE_SECRET_KEY") || "";
  try {
    const v = JSON.parse(raw);
    if (typeof v === "string") return v;
    if (v && typeof v === "object") return v.default || Object.values(v)[0];
  } catch (_) { /* plain string */ }
  return raw;
}

async function rest(path) {
  const url = Deno.env.get("SUPABASE_URL") + "/rest/v1/" + path;
  const key = serverKey();
  if (!key) throw new Error("Funkcia nemá serverový kľúč (SUPABASE_SERVICE_ROLE_KEY).");
  const headers = { apikey: key };
  if (key.startsWith("eyJ")) headers.Authorization = "Bearer " + key; // only JWT keys go in Authorization
  const r = await fetch(url, { headers });
  if (!r.ok) throw new Error("Databáza odpovedala " + r.status + ": " + (await r.text()).slice(0, 300));
  return r.json();
}

if (typeof Deno !== "undefined" && Deno.serve) {
  Deno.serve(async (req) => {
    if (req.method !== "GET" && req.method !== "HEAD") return text("Povolené je iba GET.", 405);
    const token = new URL(req.url).searchParams.get("t") || "";
    if (!/^[a-f0-9]{32,128}$/.test(token)) return text("Chýba alebo je neplatný kľúč kalendára.", 404);
    try {
      const feed = await rest("calendar_feeds?select=user_id&token=eq." + token + "&limit=1");
      if (!feed.length) return text("Tento kalendár neexistuje. Skopíruj si v diári aktuálnu adresu.", 404);
      const since = new Date(Date.now() - 400 * 86400e3).toISOString().slice(0, 10);
      const events = await rest(
        "events?select=id,title,event_date,start_time,end_time,status,notes,checklist,attachments,updated_at" +
          "&user_id=eq." + feed[0].user_id + "&event_date=gte." + since + "&order=event_date&limit=5000",
      );
      return new Response(req.method === "HEAD" ? null : buildCalendar(events), {
        status: 200,
        headers: {
          "Content-Type": "text/calendar; charset=utf-8",
          "Content-Disposition": 'inline; filename="osobny-diar.ics"',
          "Cache-Control": "no-cache, max-age=0",
        },
      });
    } catch (e) {
      return text("Kalendár sa nepodarilo pripraviť. " + (e && e.message ? e.message : ""), 500);
    }
  });
}
