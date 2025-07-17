# HobbyTracker - Supabase & Google Auth Setup Guide

## Prerequisites
- Xcode 15.0+
- A Google Cloud account
- A Supabase account

## Step 0: Configuration Setup

**IMPORTANT**: Before you can run the app, you need to create your configuration file:

1. Copy the template file:
   ```bash
   cp SupabaseConfig.swift.template SupabaseConfig.swift
   ```

2. Edit `SupabaseConfig.swift` and replace the placeholder values with your actual credentials:
   - `YOUR_SUPABASE_URL_HERE` → Your Supabase project URL
   - `YOUR_SUPABASE_ANON_KEY_HERE` → Your Supabase anon/public key  
   - `YOUR_GOOGLE_CLIENT_ID_HERE` → Your Google OAuth client ID

**Note**: The `SupabaseConfig.swift` file is gitignored to protect your credentials. Only the template file is tracked in git.

## Step 1: Install Dependencies

Add these Swift packages to your Xcode project:

1. **Supabase Swift**: `https://github.com/supabase/supabase-swift`
2. **Google Sign-In**: `https://github.com/google/GoogleSignIn-iOS`

### How to add packages:
1. In Xcode, go to **File > Add Package Dependencies**
2. Paste the URLs above one by one
3. Click **Add Package** for each

## Step 2: Google Cloud Console Setup

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select an existing one
3. Enable the **Google+ API**:
   - Go to **APIs & Services > Library**
   - Search for "Google+ API"
   - Click **Enable**

4. Create OAuth 2.0 credentials:
   - Go to **APIs & Services > Credentials**
   - Click **Create Credentials > OAuth 2.0 Client IDs**
   - Choose **macOS** as application type
   - Add your app's bundle identifier
   - Copy the **Client ID** (you'll need this for Step 0)

## Step 3: Supabase Project Setup

1. Go to [supabase.com](https://supabase.com) and create a new project
2. Wait for the project to be fully initialized

### Configure Google Auth in Supabase:
1. In your Supabase dashboard, go to **Authentication > Providers**
2. Find **Google** and toggle it **ON**
3. Paste your Google **Client ID** and **Client Secret** from Step 2
4. Add your redirect URL: `https://your-project.supabase.co/auth/v1/callback`
5. **IMPORTANT**: Disable nonce validation (to avoid nonce mismatch errors)

### Get Supabase Credentials:
1. Go to **Settings > API**
2. Copy your **Project URL** and **anon/public** key (you'll need these for Step 0)

## Step 4: Create Database Schema

In your Supabase dashboard, go to **SQL Editor** and run this SQL:

```sql
-- Create hobbies table
CREATE TABLE hobbies (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT DEFAULT '',
    color TEXT DEFAULT '#007AFF',
    total_time DOUBLE PRECISION DEFAULT 0,
    sessions JSONB DEFAULT '[]'::jsonb,
    created_date TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE hobbies ENABLE ROW LEVEL SECURITY;

-- Create policy to allow users to only see their own hobbies
CREATE POLICY "Users can view own hobbies" 
ON hobbies FOR SELECT 
USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own hobbies" 
ON hobbies FOR INSERT 
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own hobbies" 
ON hobbies FOR UPDATE 
USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own hobbies" 
ON hobbies FOR DELETE 
USING (auth.uid() = user_id);
```

## Step 5: Configure Your App

**This step is now done in Step 0!** Make sure you've created your `SupabaseConfig.swift` file from the template.

## Step 6: Update URL Schemes (if needed)

If you encounter URL handling issues:

1. In Xcode, select your app target
2. Go to **Info > URL Types**
3. Add a new URL Type with:
   - Identifier: `com.googleusercontent.apps.YOUR_CLIENT_ID`
   - URL Schemes: Your Google Client ID (reversed)

## Step 7: Test Your Setup

1. Build and run your app
2. You should see the login screen
3. Click "Sign in with Google"
4. Complete the Google OAuth flow
5. You should be redirected back to your app and see the main hobby tracking interface

## Troubleshooting

### Common Issues:

1. **"Could not find GoogleService-Info.plist"** - This is expected since we're using the configuration file approach
2. **Authentication errors** - Check that your Google Client ID is correct in both Google Cloud Console and Supabase
3. **Nonce validation errors** - Make sure you've disabled nonce validation in Supabase Auth settings
4. **Database errors** - Ensure the SQL schema was created successfully
5. **Build errors** - Make sure both Swift packages are properly added
6. **Missing config file** - Make sure you've copied and configured `SupabaseConfig.swift` from the template

### Testing Database Connection:
In Supabase dashboard > API Docs, you can test your connection using the auto-generated API calls.

## For Developers

If you're setting up this project:

1. **Never commit your actual credentials** - The `SupabaseConfig.swift` file is gitignored
2. **Always use the template** - Copy `SupabaseConfig.swift.template` to `SupabaseConfig.swift`
3. **Keep credentials secure** - Don't share your config file or commit it accidentally

## Next Steps

Once setup is complete:
- Users can sign in with Google
- Each user has their own isolated hobby data
- All existing functionality remains the same
- Users can sign out from the profile menu in the bottom-left sidebar

Your app now has full backend support with user authentication! 🎉 