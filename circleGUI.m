function circleGUI(circleX, circleY, circleRadius, InputData, Title)
    % Create a figure
    fig = figure;
    % Create an axes for the imagesc plot
    ax = axes(fig, 'Position', [0.1, 0.1, 0.8, 0.6]);

    % Plot the initial circle
    plotCircle(ax, circleX, circleY, circleRadius, InputData, Title);
    
    
    function plotCircle(ax, x, y, radius, InputData, Title)
        % Plot the circle on the axes
        theta = linspace(0, 2*pi, 100);
        xCircle = x + radius * cos(theta);
        yCircle = y + radius * sin(theta);
        imagesc(ax, InputData);  % Replace with your own data or image
        hold on
        plot(ax, xCircle, yCircle, 'b', 'LineWidth', 1);
        axis(ax, 'equal');
        title(ax, Title);

    end

    function moveCircle(ax, dx, dy)
        % Move the circle up or down
        circleY = circleY + dy;
        plotCircle(ax, circleX, circleY, circleRadius);
    end

    function changeRadius(ax)
        % Change the radius of the circle
        prompt = 'Enter new radius:';
        dlgtitle = 'Radius Input';
        dims = [1 35];
        definput = {num2str(circleRadius)};
        answer = inputdlg(prompt, dlgtitle, dims, definput);

        if ~isempty(answer)
            circleRadius = str2double(answer{1});
            plotCircle(ax, circleX, circleY, circleRadius);
        end
    end
end