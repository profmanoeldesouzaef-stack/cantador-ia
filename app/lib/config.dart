// Endereço do backend. Passe na hora de compilar:
// flutter build apk --dart-define=SUPABASE_URL=https://xxxx.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJ...
// A chave "anon" do Supabase é pública por natureza; as chaves das IAs ficam só no servidor.

const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');

bool get backendConfigurado => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;
