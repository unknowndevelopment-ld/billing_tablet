# Trendy Billing

An ESX Legacy billing tablet with a React/Vite UI. Press **F7** to invoice a nearby player or pay your own invoices from your bank account. Any job can issue invoices; there is no job allowlist.

## Install

1. Import `sql/trendy_billing.sql` into your database.
2. Put this folder in your server's `resources` directory.
3. Start the dependencies before `trendy_billing`:

```cfg
ensure oxmysql
ensure ox_lib
ensure es_extended
ensure esx_addonaccount
ensure trendy_billing
```

The included `web/dist` is ready for FiveM. To edit the UI, run `npm install` and `npm run build` inside `web` after making changes to `web/src`.

Resource files are grouped under `client/`, `server/`, `shared/`, `sql/`, and `web/`.

## Payment routing

An invoice goes to the shared `society_<jobname>` account when that account exists in `esx_addonaccount`. Otherwise, payment goes to the issuing player's bank account while that player is online. This lets any job issue invoices without requiring a society account. Invoices remain payable later when that issuer comes online.

Players can open the tablet with F7 or `/billingtablet`. Issuer and customer must be within `Config.MaxDistance` when creating an invoice. Amounts must be whole numbers from 1 to `Config.MaxAmount`. The tablet shows the latest 100 received and issued invoices. An invoice stuck in `processing` needs administrator review before its status is changed in the database.
