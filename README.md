# Storva — Flutter Web Storefront + Admin Panel

A complete, production-ready online store: responsive customer storefront,
shopping cart, checkout with coupons and shipping regions, and a full admin
panel — backed by Supabase (free tier is enough).

Runs in **demo mode** out of the box (sample data, no setup), so you can
explore everything before connecting your own backend.

## What's included

| Area | Features |
| --- | --- |
| Storefront | Responsive product grid (mobile → desktop), category filter, live search, product details, discount badges |
| Cart & checkout | Quantity editing, shipping regions, single-use coupon codes, order summary, order confirmation with WhatsApp follow-up button |
| Admin panel (`#/admin`) | Dashboard (revenue, orders, status counts), product CRUD with image upload, order management with status flow and customer WhatsApp button, coupon generator, shipping region management |
| Backend | Supabase Postgres + Auth + Storage. All prices and discounts recomputed **server-side** (tamper-proof checkout). Row Level Security on every table. |
| Safety | Visitors can only see active products/rates and place orders through a secured function. Orders, coupons and admin actions require the admin login. |

## Tech

Flutter Web (Material 3, Provider) · Supabase (Postgres, Auth, Storage) ·
no build tools beyond the Flutter SDK.

## Quick start (demo mode)

```bash
flutter pub get
flutter run -d chrome        # storefront
# admin panel: http://localhost:PORT/#/admin  (demo mode goes straight in)
```

## Going live with your own Supabase project

1. Create a free project at <https://supabase.com>
2. SQL Editor → run `supabase/schema.sql` (creates tables, policies,
   functions, storage bucket and sample data)
3. Authentication → Users → Add user (this is your admin login)
4. Edit `lib/core/config.dart`: paste your Project URL and anon key,
   set your store name, currency symbol and WhatsApp number
5. `flutter run -d chrome` to verify, then deploy (below)

Full walkthrough with screenshots: **DOCUMENTATION.html**

## Deploy

Any static host works. Example (GitHub Pages workflow is included):

```bash
flutter build web --release --base-href "/<repo-name>/"
```

Netlify / Vercel / Firebase Hosting: deploy the `build/web` folder.

## Customizing

- **Brand**: name, currency, WhatsApp number — `lib/core/config.dart`
- **Colors / theme**: `lib/core/theme.dart`
- **Demo products**: `lib/data/demo_store.dart`
- **Real catalog**: admin panel → Products (stored in Supabase)

## Project structure

```
lib/
  core/        config, theme, formatting, responsive helpers
  data/        StoreApi contract + Supabase and demo implementations
  models/      Product, Order, OrderItem, Coupon, ShippingRate
  pages/
    storefront/  home, product details, cart, checkout, order success
    admin/       login, shell, dashboard, products, orders, coupons, shipping
  state/       cart provider
  widgets/     product card, images, skeletons, empty states
supabase/
  schema.sql   complete database + security setup
```
