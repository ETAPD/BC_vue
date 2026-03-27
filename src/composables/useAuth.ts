import { supabase } from '../lib/supabase'

export async function signUp(
  email: string,
  password: string,
  fullName: string,
  phone?: string,
  country?: string,
) {
  const { data, error } = await supabase.auth.signUp({
    email,
    password,
    options: {
      data: {
        full_name: fullName,
        ...(phone ? { phone } : {}),
        ...(country ? { country } : {}),
      },
    },
  })
  if (error) throw error
  return data
}

export async function signIn(email: string, password: string) {
  const { data, error } = await supabase.auth.signInWithPassword({ email, password })
  if (error) throw error
  return data
}

export async function signOut() {
  const { error } = await supabase.auth.signOut()
  if (error) throw error
}

export async function getUser() {
  const { data } = await supabase.auth.getUser()
  return data.user
}

export async function getSession() {
  const { data } = await supabase.auth.getSession()
  return data.session
}

export async function changePassword(newPassword: string) {
  const { error } = await supabase.auth.updateUser({ password: newPassword })
  if (error) throw error
}

export async function sendPasswordReset(email: string) {
  // Sends a password reset email to the user
  // Uses the GoTrue endpoint exposed by supabase client
  const { data, error } = await supabase.auth.resetPasswordForEmail(email)
  if (error) throw error
  return data
}
