-- 1. USERS & WALLETS
CREATE TABLE profiles (
  id UUID REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  username TEXT UNIQUE,
  tokens INTEGER DEFAULT 20,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. THE MEDIA VAULT (PPV CONTENT)
CREATE TABLE media_vault (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  creator_name TEXT,
  blur_url TEXT,
  high_res_url TEXT, -- This should be a private S3/Cloudinary link
  token_price INTEGER DEFAULT 50,
  s3_key TEXT -- For Signed URLs
);

-- 3. THE LEDGER (REVENUE TRACKING)
CREATE TABLE transactions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  user_id UUID REFERENCES profiles(id),
  media_id UUID REFERENCES media_vault(id),
  amount INTEGER,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
