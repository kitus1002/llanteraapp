
import { createClient } from '@supabase/supabase-js'
import * as dotenv from 'dotenv'
import * as path from 'path'

dotenv.config({ path: '.env.local' })

const supabase = createClient(
  process.env.NEXT_PUBLIC_SUPABASE_URL!,
  process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!
)

async function checkSchema() {
  console.log("Checking tables...")
  const tables = ['empleados', 'empleado_ingreso', 'empleado_domicilio', 'empleado_banco', 'empleado_salarios']
  
  for (const table of tables) {
    const { data, error } = await supabase.from(table).select('*').limit(1)
    if (error) {
      console.log(`Table ${table}: ERROR - ${error.message}`)
    } else {
      console.log(`Table ${table}: OK - Count: ${data.length}`)
      if (data.length > 0) {
        console.log(`  Columns: ${Object.keys(data[0]).join(', ')}`)
      }
    }
  }
}

checkSchema()
