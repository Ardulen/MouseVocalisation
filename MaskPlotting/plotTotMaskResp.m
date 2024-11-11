function plotTotMaskResp(TimeVec, varargin)
P = parsePairs(varargin);
checkField(P, 'Animals', {'mouse193', 'mouse195', 'mouse196'})
checkField(P, 'Variable', {'Tex', 'Sil'})
checkField(P, 'Area', 'ACX')
checkField(P, 'FIG', 1001)

P.AnimalNum = numel(P.Animals);

P.Color = [1, 0.55, 0;0, 0.5, 0];

for i = 1:P.AnimalNum
    Animal = P.Animals{i};
    Data.(Animal) = load(['/mnt/data/Samuel/', Animal, '/TotMaskResp/TotResp', P.Area,'.mat']);
end

for j = 1:numel(P.Variable)
    Var = [P.Variable{j}, 'RespTrials'];
    P.TotVioData.(Var) = Data.(P.Animals{1}).D.(Var);
    for i = 2:P.AnimalNum
        P.TotVioData.(Var) = cat(2, P.TotVioData.(Var), Data.(P.Animals{i}).D.(Var));
        
    end
end
Leg = {'Texture response', 'Vocalization response'};

Lims = [-3, 3];
figure(P.FIG);
clf;
set(gcf, 'Color', 'w')
TRCenter = 0;
hold on
area(0, 0, 'FaceColor', [1, 0.55, 0], 'DisplayName', 'Texture', 'FaceAlpha', 0.5, 'EdgeColor', 'none')
area(0, 0, 'FaceColor', [0, 0.7, 0], 'DisplayName', 'Vocalizations', 'FaceAlpha', 0.5, 'EdgeColor', 'none')
TexRec = rectangle('Position', [TRCenter, -10, 3, 20], 'FaceColor', [1, 0.55, 0, 0.5], 'EdgeColor', 'none');
for i = 1:10
    % Calculate the x-coordinate of each rectangle
    xCenter = 0.2*(i-1);

    % Use the rectangle function to create each rectangle
    r = rectangle('Position', [xCenter, -10, 0.1, 20], 'FaceColor', [0, 0.7, 0, 0.5], 'EdgeColor', 'none');
end

for i = 1:numel(P.Variable)
    Var = [P.Variable{i}, 'RespTrials'];
    Resp = squeeze(nanmean(P.TotVioData.(Var), 2));
    SEM = std(P.TotVioData.(Var), 0, 2);
    %Plot.(Var) = errorhull(TimeVec-2, 100*Resp, 100*SEM, 'LineWidth', 1.5, 'Color', P.Color(i, :));
    plot(TimeVec-2, 100*Resp, 'LineWidth', 2, 'Color', P.Color(i, :), 'DisplayName', Leg{i})
end

xlim([-1, 2.5])
ylim(Lims)
ylabel('DF/F')
xlabel('Time(s)')
legend()
title('Average response over ACX')