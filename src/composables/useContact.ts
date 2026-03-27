import { supabase } from '../lib/supabase'

export async function submitContactMessage(msg: {
  name: string
  email: string
  subject: string
  message: string
}) {
  const { error } = await supabase.from('contact_messages').insert({
    name: msg.name,
    email: msg.email,
    subject: msg.subject,
    message: msg.message,
  })
  if (error) throw error
}
