function [ ptr ] = attach_onramp_demands(ptr,xlsx_file,range,hov_prct)

sov_prct = 1-hov_prct;

fprintf('Generating on-ramp demand config...\n');
or_id = xlsread(xlsx_file, 'On-Ramp_Flows', sprintf('g%d:g%d', range(1), range(2)));
or_id = or_id';
ORD = xlsread(xlsx_file, 'On-Ramp_Flows', sprintf('k%d:kl%d', range(1), range(2)));
has_or_dem = find(max(ORD,[],2)>0);

dp = generate_mo('demandProfile');
d = generate_mo('demand');
d.CONTENT = '';
dp.demand = repmat(d,1,2);
dp.demand(1).ATTRIBUTE.vehicle_type_id = 1;     % sov
dp.demand(2).ATTRIBUTE.vehicle_type_id = 0;     % hov
dps = repmat(dp,1,length(has_or_dem));
for i=1:length(has_or_dem)    
    dps(i).ATTRIBUTE.id = i;
    dps(i).ATTRIBUTE.link_id_org = or_id(i);
    dps(i).demand(1).CONTENT = writecommaformat(sov_prct*ORD(has_or_dem(i),:),'%.2f');
    dps(i).demand(2).CONTENT = writecommaformat(hov_prct*ORD(has_or_dem(i),:),'%.2f');
end

% put into scenario
ptr.scenario_ptr.scenario = safe_rmfield(ptr.scenario_ptr.scenario,{'DemandSet'});
ptr.scenario_ptr.scenario.DemandSet = generate_mo('DemandSet');
ptr.scenario_ptr.scenario.DemandSet.ATTRIBUTE.id = 1;
ptr.scenario_ptr.scenario.DemandSet.ATTRIBUTE.project_id = 1;
ptr.scenario_ptr.scenario.DemandSet.ATTRIBUTE.name = 'onramps';
ptr.scenario_ptr.scenario.DemandSet.demandProfile = dps;
