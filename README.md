# Billing Tablet

An ESX Legacy billing tablet with a React/Vite UI. Press **F7** to invoice a nearby player or pay your own invoices from your bank account. Any job can issue invoices; there is no job allowlist.

## Install

1. Import `sql/billing_tablet.sql` into your database.
2. Put this folder in your server's `resources` directory.
3. Start the dependencies before `billing_tablet`:

```cfg
ensure oxmysql
ensure ox_lib
ensure es_extended
ensure esx_addonaccount
ensure billing_tablet
```

The included `web/dist` is ready for FiveM. To edit the UI, run `npm install` and `npm run build` inside `web` after making changes to `web/src`.

Resource files are grouped under `client/`, `server/`, `shared/`, `sql/`, and `web/`.

If you installed the previous release and have saved invoices, rename its table before starting this version: `RENAME TABLE trendy_invoices TO billing_invoices;`. Existing installs should also rename the resource folder to `billing_tablet` and update the `ensure` line.

## Payment routing

An invoice goes to the shared `society_<jobname>` account when that account exists in `esx_addonaccount`. Otherwise, payment goes to the issuing player's bank account while that player is online. This lets any job issue invoices without requiring a society account. Invoices remain payable later when that issuer comes online.

Players can open the tablet with F7 or `/billingtablet`. Issuer and customer must be within `Config.MaxDistance` when creating an invoice. Amounts must be whole numbers from 1 to `Config.MaxAmount`. The tablet shows the latest 100 received and issued invoices. An invoice stuck in `processing` needs administrator review before its status is changed in the database.
