begin;
select plan(1);

select has_table('public'::name, 'trees'::name);

select * from finish();
rollback;
