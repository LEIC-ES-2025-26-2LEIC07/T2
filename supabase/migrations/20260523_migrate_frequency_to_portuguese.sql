-- Migrate medication frequency values from English to Portuguese
update public.medications set frequency = 'Uma vez por dia'      where frequency = 'Once daily';
update public.medications set frequency = 'Duas vezes por dia'   where frequency = 'Twice daily';
update public.medications set frequency = 'Três vezes por dia'   where frequency = 'Three times daily';
update public.medications set frequency = 'Em dias alternados'   where frequency = 'Every other day';
update public.medications set frequency = 'Semanalmente'         where frequency = 'Weekly';
update public.medications set frequency = 'Conforme necessário'  where frequency = 'As needed';
