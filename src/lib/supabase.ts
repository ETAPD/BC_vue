import { createClient } from '@supabase/supabase-js'

const supabaseUrl = import.meta.env.VITE_SUPABASE_URL as string
const supabaseKey = import.meta.env.VITE_SUPABASE_PUBLISHABLE_KEY as string

export const supabase = createClient(supabaseUrl, supabaseKey, {
  auth: {
    autoRefreshToken: false,
    persistSession: true,
  },
})

// Sign the user out after 1 hour of inactivity
const SESSION_DURATION_MS = 60 * 60 * 1000 // 1 hour

let sessionTimer: ReturnType<typeof setTimeout> | null = null

function resetSessionTimer() {
  if (sessionTimer) clearTimeout(sessionTimer)
  sessionTimer = setTimeout(async () => {
    await supabase.auth.signOut()
  }, SESSION_DURATION_MS)
}

supabase.auth.onAuthStateChange((event) => {
  if (event === 'SIGNED_IN' || event === 'TOKEN_REFRESHED') {
    resetSessionTimer()
  } else if (event === 'SIGNED_OUT') {
    if (sessionTimer) {
      clearTimeout(sessionTimer)
      sessionTimer = null
    }
  }
})
