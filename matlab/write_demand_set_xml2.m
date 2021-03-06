function write_demand_set_xml2(fid, xlsx_file, range, or_id, ORS, orgf2, orgf3, orgf4)
% ORS - configuration table for specially treated on-ramps
% fid - file descriptor for the output xml
% xlsx_file - full path to the configuration spreadsheet
% range - row range to be read from the spreadsheet
% or_id - array of on-ramp link IDs
% ORS - configuration table for specially treated on-ramps
% orgf2-4 - flags indicating that On-Ramp_GrowthFactors2,3,4 should be considered

disp('  C. Generating demand set...');

% Link IDs
hov_prct = xlsread(xlsx_file, 'Configuration', sprintf('c%d:c%d', range(1), range(2)))';
ORD = xlsread(xlsx_file, 'On-Ramp_CollectedFlows', sprintf('k%d:kl%d', range(1), range(2)));
ORK = xlsread(xlsx_file, 'On-Ramp_Knobs', sprintf('k%d:kl%d', range(1), range(2)));
ORH = xlsread(xlsx_file, 'HOV_Portion', sprintf('k%d:kl%d', range(1), range(2)));
ORGF = xlsread(xlsx_file, 'On-Ramp_GrowthFactors', sprintf('k%d:kl%d', range(1), range(2)));
if orgf2 | orgf3 | orgf4
  ORGF2 = xlsread(xlsx_file, 'On-Ramp_GrowthFactors_2', sprintf('k%d:kl%d', range(1), range(2)));
  if orgf3 | orgf4
    ORGF3 = xlsread(xlsx_file, 'On-Ramp_GrowthFactors_3', sprintf('k%d:kl%d', range(1), range(2)));
    if orgf4
      ORGF4 = xlsread(xlsx_file, 'On-Ramp_GrowthFactors_4', sprintf('k%d:kl%d', range(1), range(2)));
      ORGF3 = ORGF3 .* ORGF4;
    end
    ORGF2 = ORGF2 .* ORGF3;
  end
  ORGF = ORGF .* ORGF2;
end
ORD = ORD .* ORK .* ORGF;


sz = size(ORD, 1);

fprintf(fid, ' <DemandSet id="1" name="onramps" project_id="1">\n');

for i = 1:sz
  if or_id(i) ~= 0
    ors = find_or_struct(ORS, or_id(i));
    if isempty(ors)
      %write_demand_profile_xml(fid, or_id(i), ORD(i, :), hov_prct(i));
      write_demand_profile_xml(fid, or_id(i), ORD(i, :), ORH(i, :));
    else      
      if isempty(ors.feeders)
        links = ors.peers;
        lhov = ors.peer_hov_portion;
      else      
        links = ors.feeders;
        lhov = ors.feeder_hov_portion;
      end
      in_count = size(links, 2);
      for j = 1:in_count
        sz2 = 4;
        if orgf4
          sz2 = 6;
        elseif orgf3
          sz2 = 5;
        end
        idx = (j - 1) * sz2 + 1;
	% blank - demand
	% +1 - knobs
	% +2 - growth factors
	% +3 - growth factors 2
	% +4 - growth factors 3
	% +5 - growth factors 4
        ord = ors.data(idx, :) .* ors.data(idx + 1, :) .* ors.data(idx + 2, :);
        if orgf2 | orgf3 | orgf4
          ord = ord .* ors.data(idx + 3, :);
          if orgf3 | orgf4
            ord = ord .* ors.data(idx + 4, :);
            if orgf4
              ord = ord .* ors.data(idx + 5, :);
            end
          end
        end
        write_demand_profile_xml(fid, links(j), ord, lhov(j));
      end
    end
  end
end

fprintf(fid, ' </DemandSet>\n\n');

return;


function write_demand_profile_xml(fid, or_id, demand, hov_prct)
% fid - file descriptor for the output xml
% or_id - on-ramp ID
% demand - array of total demand values
% hov_prct - HOV portion of total demand

sz = size(demand, 2);
hov_d = hov_prct .* demand;
gp_d = demand - hov_d;

fprintf(fid, '   <demandProfile id="%d" link_id_org="%d" dt="300" start_time="0">\n', or_id, or_id);

fprintf(fid, '    <demand vehicle_type_id="0">%f', hov_d(1));
for i = 2:sz
  fprintf(fid, ',%f', hov_d(i));  
end
fprintf(fid, '</demand>\n');

fprintf(fid, '    <demand vehicle_type_id="1">%f', gp_d(1));
for i = 2:sz
  fprintf(fid, ',%f', gp_d(i));  
end
fprintf(fid, '</demand>\n');

fprintf(fid, '   </demandProfile>\n');

return;
