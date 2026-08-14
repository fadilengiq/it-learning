// =========================================
// IT Learning Hub
// Supabase Configuration
// =========================================

const SUPABASE_URL = "https://iimfqxsrwnlgfcqzkgqf.supabase.co";

const SUPABASE_PUBLISHABLE_KEY =
    "sb_publishable_Ga2NaG0y5afLWDmi5rYjNw_P1CRMjAx";

// Create Supabase client
const supabaseClient = window.supabase.createClient(
    SUPABASE_URL,
    SUPABASE_PUBLISHABLE_KEY
);