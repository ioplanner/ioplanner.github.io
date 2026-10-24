# ioPlanner – osobný diár (GitHub + Supabase)

Súkromný kalendár s mesačným a týždenným pohľadom, kanban nástenkou (*Naplánované / Prebieha / Hotovo*), poznámkami a checklistami. Funguje úplne bez Claude, na bezplatných účtoch **Supabase** (databáza) a **GitHub** (webová stránka).

- Adresa: **https://ioplanner.github.io/**
- Pohľady sa dajú otvoriť aj priamo: `#mesiac`, `#tyzden`, `#nastenka`.
- Na mobile: Safari → Zdieľať → *Pridať na plochu*, Chrome → ⋮ → *Pridať na plochu*.

---

## 1. Supabase (databáza)

1. V projekte otvor **SQL Editor** → **New query**, vlož celý obsah súboru **supabase.sql** a stlač **Run**. Má sa ukázať *Success*.
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
| Diár zrazu nič nenačíta | projekt v Supabase je pozastavený (*Paused*), klikni **Restore project** |
