import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static const String url = 'https://bbincwspuiykgvfwajty.supabase.co';
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJiaW5jd3NwdWl5a2d2ZndhanR5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjU2OTMzMjIsImV4cCI6MjA4MTI2OTMyMn0.KXfx67xkZ5iH9Fb7XiYt6OrmlJTPpPCV0vuMcDMq4cE';
  
  static SupabaseClient get client => Supabase.instance.client;
}
