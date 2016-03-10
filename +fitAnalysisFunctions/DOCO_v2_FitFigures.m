function DOCO_v2_FitFigures(fitobjnames,fitobjs)
    this = fitobjs{1};

    % Params for spectral plots
    xlims = [2665 2695];
    ylims = [-0.02 0.02];
    fitoffset = 0.001;
    figh = 400;
    figw = 800;
    figure('Position', [100, 100, figw,figh]); 
    subplot(3,1,1); htop = gca;
    subplot(3,1,2); hmiddle = gca;
    subplot(3,1,3); hbottom = gca;
    y0 = 0.15;
    x0 = 0.10;
    xf = 0.95;
    ploth = 0.24;
    plotspacing = 0.05;
    ay = 0.045;
    set(hbottom,'Position',[x0 y0 xf-x0 ploth]);
    set(hmiddle,'Position',[x0 y0+ploth+plotspacing xf-x0 ploth]);
    set(htop,'Position',[x0 y0+2*ploth+2*plotspacing xf-x0 ploth]);
    atop = annotation('textbox',[x0 y0+3*ploth+2*plotspacing-ay .3 .05],'String','text3','LineStyle','none','FontWeight','bold','FontSize',12);
    amiddle = annotation('textbox',[x0 y0+2*ploth+plotspacing-ay .3 .05],'String','text2','LineStyle','none','FontWeight','bold','FontSize',12);
    abottom = annotation('textbox',[x0 y0+ploth-ay .3 .05],'String','text1','LineStyle','none','FontWeight','bold','FontSize',12);
    plotlinewidth = 1;
    expplotcolor = [0.247 0.247 0.247];
    
    % Set top, middle, bottom indices
    indbottom = 3;
    indmiddle = 10;
    indtop = 26;
    
    % Construct the top plot for the figure
    axes(htop);
    ind = indtop;
    atop.String = sprintf('%i \\mus',this.t(ind));
    plot(this.wavenum(:),reshape(this.y(:,:,ind),[],1)-min(reshape(this.y(:,:,ind),[],1)),'Color',expplotcolor,'LineWidth',plotlinewidth);
    hold(gca,'on');
    co = [  1 1 1;...
            0    0.4470    0.7410;...
            0.8500    0.3250    0.0980;...
            0.4940    0.1840    0.5560;...
            0.4660    0.6740    0.1880;...
            0.6350    0.0780    0.1840];
    set(gca,'ColorOrder',co);
    for i = 1:numel(this.fitbNames)
        indx = this.fitbNamesInd(i);
        [scaleout, fitcolor, scaleouttext] = getscalingfactor(this.fitbNames{i});
        y = this.fitM(:,indx).*this.fitb(indx,ind);
        if ~isempty(fitcolor)
            plot(gca,this.wavenum(:),-scaleout*(y-min(y))-fitoffset,'-','LineWidth',plotlinewidth,'Color',fitcolor);
        else
            %plot(gca,this.wavenum(:),-scaleout*(y-min(y))-fitoffset,'-','LineWidth',plotlinewidth);
        end
        hold on;
    end
    hold off;
    xlim(xlims);
    ylim(ylims);
    set(gca,'XTickLabel',[]);
    %set(gca,'YTick',[]);
    %legend({'Experiment',this.fitbNames{:}});
    
    % Construct the middle plot for the figure
    axes(hmiddle);
    ind = indmiddle;
    amiddle.String = sprintf('%i \\mus',this.t(ind));
    plot(this.wavenum(:),reshape(this.y(:,:,ind),[],1)-min(reshape(this.y(:,:,ind),[],1)),'Color',expplotcolor,'LineWidth',plotlinewidth);
    hold(gca,'on');
    co = [  1 1 1;...
            0    0.4470    0.7410;...
            0.8500    0.3250    0.0980;...
            0.4940    0.1840    0.5560;...
            0.4660    0.6740    0.1880;...
            0.6350    0.0780    0.1840];
    set(gca,'ColorOrder',co);
    for i = 1:numel(this.fitbNames)
        indx = this.fitbNamesInd(i);
        [scaleout, fitcolor, scaleouttext] = getscalingfactor(this.fitbNames{i});
        y = this.fitM(:,indx).*this.fitb(indx,ind);
        if ~isempty(fitcolor)
            plot(gca,this.wavenum(:),-scaleout*(y-min(y))-fitoffset,'-','LineWidth',plotlinewidth,'Color',fitcolor);
        else
            %plot(gca,this.wavenum(:),-scaleout*(y-min(y))-fitoffset,'-','LineWidth',plotlinewidth);
        end
        hold on;
    end
    hold off;
    %legend({'Experiment',this.fitbNames{:}});
    xlim(xlims);
    ylim(ylims);
    set(gca,'XTickLabel',[]);
    ylabel('Absorbance');
    
    % Construct the bottom plot for the figure
    axes(hbottom);
    ind = indbottom;
    abottom.String = sprintf('%i \\mus',this.t(ind));
    plot(this.wavenum(:),reshape(this.y(:,:,ind),[],1)-min(reshape(this.y(:,:,ind),[],1)),'Color',expplotcolor,'LineWidth',plotlinewidth);
    hold(gca,'on');
    co = [  1 1 1;...
            0    0.4470    0.7410;...
            0.8500    0.3250    0.0980;...
            0.4940    0.1840    0.5560;...
            0.4660    0.6740    0.1880;...
            0.6350    0.0780    0.1840];
    set(gca,'ColorOrder',co);
    legnames = {};
    for i = 1:numel(this.fitbNames)
        indx = this.fitbNamesInd(i);
        [scaleout, fitcolor, legendtext] = getscalingfactor(this.fitbNames{i});
        y = this.fitM(:,indx).*this.fitb(indx,ind);
        if ~isempty(fitcolor)
            legnames = {legnames{:},legendtext};
            plot(gca,this.wavenum(:),-scaleout*(y-min(y))-fitoffset,'-','LineWidth',plotlinewidth,'Color',fitcolor);
        else
            %plot(gca,this.wavenum(:),-scaleout*(y-min(y))-fitoffset,'-','LineWidth',plotlinewidth);
        end
        hold on;
    end
    hold off;
    xlim(xlims);
    ylim(ylims);
    %set(gca,'YTick',[]);
    %legend({'Experiment',this.fitbNames{:}});
    %tightfig
    xlabel 'Wavenumber [cm^{-1}]';
    legend({['Exp                 ' char(30)],legnames{:}},'Orientation','horizontal','Box','off','Position',[0.33 0.302 0.514 0.08]);
    
    set(hbottom,'FontSize',13);
    set(hmiddle,'FontSize',13);
    set(htop,'FontSize',13);
    
    % Construct a plot of conc vs time
    figure('Position', [100, 100, figw,figh]);
    axes();
    legnames = {};
    pathlength = 14700;
    for i = 1:numel(this.fitbNames)
        ind = this.fitbNamesInd(i);
        [scaleout, fitcolor, legendtext] = getscalingfactor(this.fitbNames{i});
        if ~isempty(fitcolor)
            legnames = {legnames{:},legendtext};
            indt = (this.t <= 2000);
            x = this.t;
            y = scaleout*this.fitb(ind,:)/pathlength;
            dy = scaleout*this.fitbError(ind,:)/pathlength;
            errorbar(x(indt),y(indt),dy(indt),'o-','Color',fitcolor);
        end
        hold on;
    end
    xlabel('Time [\mus]');
    scaleyaxis(1e-12);
    ylabel('Concentration x10^{-12} [mlc cm^{-3}]');
    legend(legnames);
    set(gca,'FontSize',12);
    xlim([-100 2100]);
    
    function [scaleout, fitcolor, legendtext] = getscalingfactor(fitname)
        switch fitname
            case 'trans-DOCO'
                scaleout = 4;
                legendtext = 'trans-DOCO (x4)';
                fitcolor = [0.871    0.49    0.0];
            case 'D2O'
                scaleout = 1;
                legendtext = 'D_2O';
                fitcolor = [0.4660    0.6740    0.1880];
            case 'OD'
                scaleout = 1;
                legendtext = 'OD';
                fitcolor = [0    0.4470    0.7410];
            otherwise
                scaleout = 1;
                legendtext = '';
                fitcolor = [];
        end
    end
end