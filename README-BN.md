# Nobosaj Cosmetics (নবসাজ) — ওয়েবসাইট প্যাকেজ

এই প্যাকেজে মোবাইল-ফ্রেন্ডলি বাংলা/English কসমেটিকস শপের ওয়েব ফাইল, লোগো, Supabase ডেটাবেস SQL এবং বিনামূল্যের হোস্টিং নির্দেশনা আছে।

## এখন কী আছে
- পণ্যের তালিকা, দাম (৳), ক্যাটাগরি ও সার্চ
- কার্ট ও Cash on Delivery অর্ডার ফর্ম
- কাস্টমার ফিডব্যাক
- Supabase Auth দিয়ে লগইন/সাইনআপের কাঠামো
- Admin/Factory role-ভিত্তিক ড্যাশবোর্ড কাঠামো
- পণ্য ও স্টক ব্যবস্থাপনার প্রাথমিক স্ক্রিন
- Nobosaj-এর SVG লোগো

## গুরুত্বপূর্ণ সীমাবদ্ধতা
- নমুনা পণ্যের নাম/দাম/স্টক ডেমো; আপনার আসল পণ্যের তালিকা দিয়ে বদলাতে হবে।
- Supabase URL ও anon/public key না বসানো পর্যন্ত লগইন, অনলাইন অর্ডার, ফিডব্যাক ও লাইভ ডেটাবেস চালু হবে না।
- অনলাইন পেমেন্ট গেটওয়ে সংযুক্ত নেই; আপাতত COD নির্বাচন করুন।
- এটি প্রাথমিক স্টোরফ্রন্ট, সম্পূর্ণ অডিট করা production commerce system নয়। বাস্তব বিক্রির আগে checkout-এ server-side stock/price validation, order item tables, stock movement log, policies এবং privacy/return/delivery তথ্য সম্পন্ন করতে হবে।

## বিনামূল্যে অনলাইনে প্রকাশ (Cloudflare Pages + Supabase)
1. Supabase-এ একটি project খুলুন: https://supabase.com/
2. Supabase → SQL Editor-এ `supabase-schema.sql` ফাইলের সম্পূর্ণ SQL paste করে Run করুন।
3. Project Settings → API থেকে Project URL এবং anon/public key নিন। `www/index.html`-এ `SUPABASE_URL` ও `SUPABASE_ANON_KEY`-এ বসান। `service_role` key কখনো ওয়েবসাইটে বসাবেন না।
4. সাইটে নিজের email দিয়ে account তৈরি করুন। তারপর Supabase SQL Editor-এ নিজের email বসিয়ে admin role দিন:

```sql
update public.profiles
set role='admin'
where id=(select id from auth.users where email='YOUR_EMAIL');
```

5. Cloudflare-এ account খুলুন: https://dash.cloudflare.com/
6. Workers & Pages → Create → Pages → Direct Upload নির্বাচন করুন। এই প্যাকেজের `www` ফোল্ডারের ভেতরের ফাইলগুলো আপলোড করুন (অথবা `www` ফোল্ডারটি deploy করুন)।
7. Cloudflare একটি বিনামূল্যের `*.pages.dev` ঠিকানা দেবে। সেই ঠিকানায় সবাই ওয়েবসাইট দেখতে পারবে।

## নিরাপত্তা
- আপনার পাসওয়ার্ড কাউকে বা ChatGPT-তে পাঠাবেন না। Supabase-এ নিজে শক্তিশালী পাসওয়ার্ড তৈরি করুন।
- Admin role শুধু মালিকের account-এ দিন। Signup থেকে কেউ নিজে admin হতে পারবে না।
- Supabase RLS policies পরীক্ষা না করে বাস্তব কাস্টমার তথ্য/অর্ডার সংগ্রহ শুরু করবেন না।
- Free plan-এর সীমা/নিয়ম পরিবর্তিত হতে পারে; প্রকাশের আগে provider-এর বর্তমান শর্ত দেখুন।


## নতুন এডিটিং সুবিধা

- Admin Dashboard → Shop settings থেকে দোকানের নাম, tagline, ঠিকানা, ফোন, WhatsApp, লোগো URL, হোমপেজের শিরোনাম/বর্ণনা এবং ফুটারের লেখা বদলানো যাবে।
- Admin Dashboard → Products থেকে পণ্য যোগ ও Edit করা যাবে।
- Factory Panel-এ Factory role-এর ব্যবহারকারীরা স্টক ও অর্ডারের কাজ দেখতে পারবেন; দোকানের পরিচিতি ও Admin সেটিংস বদলাতে পারবেন না।
- নতুন `store_settings` টেবিলসহ আপডেট করা `supabase-schema.sql` Supabase SQL Editor-এ চালাতে হবে।
- Supabase যুক্ত না থাকলে সেটিংস শুধু সেই ডিভাইসের ব্রাউজারে সেভ হবে; সবার ওয়েবসাইটে দেখাতে Supabase URL/anon key এবং SQL সেটআপ আবশ্যক।
