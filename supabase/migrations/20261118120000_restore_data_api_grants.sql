-- Since 2026-10-30 Supabase no longer grants Data API roles (anon, authenticated,
-- service_role) access to new tables in public. The upstream migrations relied on
-- those implicit grants, so fresh databases (e.g. E2E CI) fail with 42501.
-- Grant per table only what the frontend, edge functions and e2e fixtures use;
-- row access stays controlled by RLS. New tables must grant explicitly.
-- SECURITY DEFINER RPCs (waterings_for_*, remove_account, ...) need no table grants.

-- Public map data
GRANT SELECT ON public.trees TO anon, authenticated;

-- Frontend (logged in)
GRANT SELECT ON public.profiles TO authenticated;
GRANT UPDATE (username) ON public.profiles TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.trees_adopted TO authenticated;
GRANT SELECT, INSERT, DELETE ON public.trees_watered TO authenticated;
-- submit_contact_request / check_contact_request run with the user's JWT.
-- No UPDATE: the rate limit counts rows with contact_mail_id set, so users must
-- not be able to clear it. The function writes contact_mail_id as service_role.
GRANT SELECT, INSERT ON public.contact_requests TO authenticated;

-- service_role: gdk_stats, contact request checks, e2e fixtures
GRANT SELECT, INSERT, UPDATE ON public.profiles TO service_role;
GRANT SELECT, INSERT, DELETE ON public.trees_adopted TO service_role;
GRANT SELECT, INSERT, DELETE ON public.trees_watered TO service_role;
GRANT SELECT, UPDATE ON public.contact_requests TO service_role;
GRANT SELECT ON public.daily_weather_data TO service_role;
GRANT SELECT ON public.trees_count, public.total_tree_species_count, public.most_frequent_tree_species TO service_role;
