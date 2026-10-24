# ioPlanner – osobný diár (GitHub + Supabase)

Súkromný kalendár s mesačným a týždenným pohľadom, kanban nástenkou (*Naplánované / Prebieha / Hotovo*), poznámkami, checklistami a PDF prílohami (cenové ponuky, faktúry). Funguje úplne bez Claude, na bezplatných účtoch **Supabase** (databáza) a **GitHub** (webová stránka).

- Adresa: **https://ioplanner.github.io/**
- Pohľady sa dajú otvoriť aj priamo: `#mesiac`, `#tyzden`, `#nastenka`.
- Na mobile: Safari → Zdieľať → *Pridať na plochu*, Chrome → ⋮ → *Pridať na plochu*.
- **Stav sa nastavuje sám podľa dátumu:** budúce akcie sú *Naplánované*, dnešné (aj viacdňové, ktoré práve bežia) *Prebieha*, minulé *Hotovo*.

---

## 1. Supabase (databáza)

1. V projekte otvor **SQL Editor** → **New query**, vlož celý obsah súboru **supabase.sql** a stlač **Run**. Má sa ukázať *Success*. To isté potom urob so súbormi **supabase-prilohy.sql** (prílohy PDF) **supabase-viacdnove.sql** (akcie cez viac dní) a **supabase-mzdy.sql** (pracovné miesta a mzdy).
2. **Vytvor si prihlasovací účet:** **Authentication** → **Users** → **Add user** → **Create new user**. Zadaj e-mail a heslo a zaškrtni **Auto Confirm User**.
3. **Zakáž registráciu cudzím:** **Authentication** → *Sign In / Providers* → vypni **Allow new users to sign up**.
4. **Údaje na pripojenie:** **Project Settings** → **API Keys** → verejný kľúč **publishable** (`sb_publishable_…`), nie *secret* / *service_role*.

## 2. Údaje v index.html

Na začiatku skriptu v **index.html**:

```
const SUPABASE_URL = "https://mtifpeafpmkeimqiqfym.supabase.co";
const SUPABASE_KEY = "sb_publishable_...";
```

Verejný kľúč môže byť v stránke viditeľný, je na to určený. Akcie chránia prihlásenie a pravidlá zo súboru supabase.sql: každý vidí iba svoje.

Kým kľúč chýba, diár ukladá akcie len v prehliadači (v hlavičke svieti „len toto zariadenie“).

## 3. GitHub Pages

**Settings** → **Pages** → *Source: Deploy from a branch*, *Branch: main*, priečinok */ (root)* → **Save**. Na bezplatnom účte musí byť repozitár **Public**.

Zmeny: otvor súbor na GitHube → ceruzka → uprav → **Commit changes**. Stránka sa obnoví do 1 – 2 minút.

---

## Časté problémy

| Čo vidíš | Riešenie |
|---|---|
| „len toto zariadenie“ v hlavičke | v index.html chýba kľúč (krok 2) |
| „V databáze chýba tabuľka“ | spusti supabase.sql (krok 1) |
| „Databáza zápis odmietla“ | spusti supabase.sql znova, celé naraz |
| „Nesprávny e-mail alebo heslo“ | skontroluj účet v Authentication → Users |
| „Úložisko na prílohy ešte neexistuje“ alebo „Databáza ešte nepozná prílohy“ | spusti supabase-prilohy.sql |
| „Databáza ešte nepozná viacdňové akcie“ | spusti supabase-viacdnove.sql |
| „Databáza ešte nepozná pracovné miesta“ | spusti supabase-mzdy.sql |
| „chýba tabuľka pre kalendár“ | spusti supabase-kalendar.sql |
| Kalendár Apple hlási chybu alebo „Vyskúšať adresu“ ukáže *Missing authorization header* | vo funkcii **swift-service** vypni **Verify JWT** |
| „Vyskúšať adresu“ ukáže *Function not found* | funkcia ešte nie je nasadená (Kalendár Apple, krok 2) |
| Diár zrazu nič nenačíta | projekt v Supabase je pozastavený (*Paused*), klikni **Restore project** |

## Prílohy

- V detaile akcie → **+ Priložiť PDF**. Pri každom súbore vyberieš druh: *Cenová ponuka*, *Faktúra* alebo *Iné*.
- Súbory sú v súkromnom úložisku Supabase (*Storage → prilohy*), každý vidí iba svoje. **Otvoriť** vytvorí dočasný odkaz platný 10 minút.
- Max 20 MB na súbor, bezplatný plán Supabase má spolu 1 GB.

## Pracovné miesta a mzdy

- **Pracovné miesto** je odberateľ s dohodnutou sadzbou: **hodinová** (€/hod), **denná** (€/deň) alebo **úkolová** (€/úlohu).
- V detaile akcie ho vyberieš pod názvom, nové pridáš priamo tam (*+ Nové pracovné miesto…*) alebo v pohľade **Mzdy**.
- Pracovné miesto sa dá uložiť aj **bez sadzby**, stačí názov a druh. Sadzbu doplníš neskôr v *Mzdy → Upraviť* alebo priamo pri akcii.
- **Úkolová sadzba:** sumu zadáš pri každej akcii zvlášť (*Suma za túto úlohu*). Ak má pracovné miesto vyplnenú obvyklú sumu, predvyplní sa a dá sa prepísať.
- Množstvo sa doplní samo: hodiny z času od – do, dni z dátumov. Dá sa prepísať, napr. po odpočítaní prestávky.
- Akcie, pri ktorých chýba suma, sadzba alebo hodiny, sa do súčtu nezapočítajú a pohľad **Mzdy** na ne upozorní.
- Sadzba sa uloží pri akcii, takže neskoršia zmena sadzby nezmení staré akcie. Pri akcii sa dá upraviť aj ručne.
- Pohľad **Mzdy** (`#mzdy`): suma za mesiac, súčty podľa pracovných miest a zoznam akcií. Akcia patrí do mesiaca, v ktorom začína. Voľba *Len hotové* započíta iba akcie v stave Hotovo.
- Pracovné miesto, s ktorým už nespolupracuješ, **archivuj**: zmizne z výberu, staré akcie a sumy ostanú.

## Kalendár Apple (iCloud)

Akcie z diára sa dajú odoberať v aplikácii Kalendár na iPhone, iPade a Macu. Ide to jedným smerom: v Kalendári akcie vidíš, upravuješ ich v diári. Zmeny sa prejavia zvyčajne do 15 – 60 minút.

**Jednorazové nastavenie v Supabase:**

1. **SQL Editor** → **New query** → vlož obsah **supabase-kalendar.sql** → **Run**.
2. **Edge Functions** → **Deploy a new function** → **Via Editor**. Názov funkcie je v tomto projekte **`swift-service`** (ak vytvoríš novú s iným názvom, zmeň `FEED_FUNCTION` na začiatku index.html). Celý obsah súboru **supabase/functions/kalendar/index.ts** vlož do editora namiesto ukážkového kódu → **Deploy function**.
3. Vo funkcii **swift-service** otvor **Details** (alebo *Settings*) a **vypni Verify JWT** (*Enforce JWT verification*) → **Save**. Kalendár Apple sa neprihlasuje, prístup chráni tajný kľúč v adrese.

**V diári:** tlačidlo **Kalendár Apple** → **Pridať do Kalendára**. Alebo adresu skopíruj a pridaj ručne:

- **Mac:** Kalendár → *Súbor* → *Nový odoberaný kalendár* → vlož adresu → *Umiestnenie: iCloud*, *Obnovovať: každých 15 minút*. Kalendár sa potom zobrazí aj na iPhone a iPade.
- **iPhone:** *Nastavenia → Aplikácie → Kalendár → Účty kalendárov → Pridať účet → Iné → Pridať odoberaný kalendár*.

Adresu nikomu neposielaj. Ak ju niekto získa, v diári klikni **Vytvoriť novú adresu**, stará prestane fungovať.
