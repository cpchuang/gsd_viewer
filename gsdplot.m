% gsdplot to visdualize gsd_192 data.
%
%   +1.0 2018/05/15 Initial release
%
% Copyright 2018 Andrew Chuang (chuang.cp@gmail.com)
% $Revision: 1.0 $  $Date: 2018/05/15 $

function gsdplot(da,opt)

fsa = 13;
fst = 18;

if nargin == 1
    opt = '';
end

%%%%%%  define default option %%%%%

if isfield(opt,'datalim')
    datalim = opt.datalim;
else
    % range for (Ch/E/d),(posno),(Intensity)
    datalim = {'auto','auto','auto'}; 
end

if isfield(opt,'normalize')
    normalize = opt.normalize;
else
    normalize = 0;
end

if isfield(opt,'detno')
    detno = opt.detno;
else
    detno = 1;
end

if isfield(opt,'do_export')
    do_export = opt.do_export;
else
    do_export = 0;
end

if isfield(opt,'x_unit')
    x_unit = lower(opt.x_unit);
else
    x_unit = 'ch';
end

if isfield(opt,'yscale')
    switch opt.yscale
        case 1
            y_scale = 'linear';
        otherwise
            y_scale = 'log';
    end
else
    y_scale = 'log';
end

if isfield(opt,'xscaling')
    x_scaling = opt.xscaling;
else
    x_scaling = 1;
end

if isfield(opt,'x_range')
    x_range = opt.x_range;
else
    x_range = ':';
end

if isfield(opt,'avg_1D')
    avg_1D = opt.avg_1D;
else
    avg_1D = 0;
end

if isfield(opt,'title')
    title_text = opt.title;
else
    title_text = '';
end

if isfield(opt,'posno')
    posno = opt.posno;
else
    posno = 1;
end

if isfield(opt,'type')
    type = opt.type;
else
    type = '2draw';
end

if isfield(opt,'scno')
    scno = opt.scno(1);   % only plot one scan at a time. (May.17)
else
    scno = 1;
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%% pre-processing
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if isfield(opt,'Inst')
    detpar = opt.Inst(detno).par;
elseif ~isfield(da(1),'Inst')
    fprintf('No Instrument parameters provided!!\n');
    fprintf('Use default TOA  = 3 (deg)\n');
    fprintf('Use default Ch2E = [0.052 0];\n');
    detpar = zeros(192,3);
    detpar(:,1) = 0.052;
    detpar(:,3) = 3;
end

% calculate E_grid, d_grid
hc = 12.398419057638671;
% for i = 1:2
%     da(scno).Inst(i).E_grid = [1:8192]*da(1).Inst(i).Ch2E(1)+da(1).Inst(i).Ch2E(2);
%     da(scno).Inst(i).d_grid = hc./da(scno).Inst(i).E_grid*0.5/sind(da(1).Inst(i).TOA/2);
% end

switch lower(type)
    case '2draw'
        %%%%%% Prepare figure
        hfig = findall(0,'Tag','gsd_fig_map');
        if ishandle(hfig)
            fig = hfig(1);
            clf(fig,'reset');
            set(fig,'Tag','gsd_fig_map');
        else
            fig = figure(192);
            set(fig,'Position',[100 100 800 960],'Tag','gsd_fig_map');
        end

        cc = lines(100);
        ax = axes('parent',fig,'fontsize',fsa,'box','on');
        axes(ax)
        grid on;
        
        switch lower(x_unit)
            case {'ch','channel'}
                img = da(1).data{scno};
                x_grid = 1:4096;
                xlabeltx = 'channel';
            case {'e','energy'}
                xlabeltx = 'Energy (keV)';
                x_grid = 5:0.05:210;
                img = zeros(192,length(x_grid));
                for i = 1:192
                    if detpar(i,1) == 0
                        detpar(i,1) = 0.05;
                    end
                    xdata = polyval(detpar(i,1:end-1),[1:4096]);
                    ydata = da(1).data{scno}(i,:);
                    img(i,:) =  interp1(xdata,ydata,x_grid,'pchip');
                end
                img(img<0) = 0;
            case {'d'}
                xlabeltx = 'd-spacing (Angstron)';
                x_grid = 0.7:0.01:5;
                img = zeros(192,length(x_grid));
                for i = 1:192
                    if detpar(i,1) == 0
                        detpar(i,1) = 0.05;
                    end
                    E_list = polyval(detpar(i,1:end-1),[1:4096]);
                    xdata = hc./E_list/2./sind(detpar(i,end)/2); 
                    ydata = da(1).data{scno}(i,:);
                    img(i,:) =  interp1(xdata,ydata,x_grid,'pchip');
                end
                img(img<0) = 0;                
            otherwise
                fprintf('selected x_unit is not supported yet\n')
                return
        end
        ylabeltx = 'Pixel no.';
        assignin('base','img',img);
        imagesc(x_grid,1:192,log(img),'parent',ax)
        set(ax,'clim',[0 max(log(img(:)))]);
        xrange   = opt.datalim{1};
        pxrange  = opt.datalim{2};

        xlim(xrange)
        
        if ~ischar(pxrange); ylim(pxrange); end

        xlabel(xlabeltx,'fontsize',fsa,'parent',ax)
        ylabel(ylabeltx,'fontsize',fsa,'parent',ax)
        title(title_text,'fontsize',fst,'parent',ax)
    case 'raw'
        %%%%%% Prepare figure
        hfig = findall(0,'Tag','gsd_fig_1d');
        if ishandle(hfig)
            fig = hfig(1);
            clf(fig,'reset');
            set(fig,'Tag','gsd_fig_1d');
        else
            fig = figure(193);
            set(fig,'Position',[100 100 800 600],'Tag','gsd_fig_1d');
        end

        cc = lines(100);
        ax = axes('parent',fig,'fontsize',fsa,'box','on');
        axes(ax)
        grid on;
        
        img = da(1).data{scno};
        
        switch lower(x_unit)
            case {'ch','channel'}
                %img = da(scno).data{detno};
                xdata = 1:4096;
                xlabeltx = 'channel';
            case {'e','energy'}
                xlabeltx = 'Energy (keV)';
            case {'d'}
                xlabeltx = 'd-spacing (Angstron)';                
            otherwise
                fprintf('selected x_unit is not supported yet\n')
                return
        end
        
        for i = 1:length(posno)
            ydata = img(posno(i),:);
            switch lower(x_unit)
                case {'e','energy'}
                    xdata = [1:4096]*detpar(posno(i),1)+detpar(posno(i),2);
                case {'d'}
                    E_list = [1:4096]*detpar(posno(i),1)+detpar(posno(i),2);
                    xdata = hc./E_list/2./sind(detpar(posno(i),3)/2);
            end
            line(xdata,ydata,'marker','.','color',cc(i,:),'displayname',sprintf('px-%d',posno(i)))
        end
        
        ylabeltx = 'Intensity';
        xrange   = opt.datalim{1};
        intrange  = opt.datalim{3};

        xlim(xrange)
        ylim(intrange)
        if opt.yscale==0
            set(ax,'yscale','log')
        end

        xlabel(xlabeltx,'fontsize',fsa,'parent',ax)
        ylabel(ylabeltx,'fontsize',fsa,'parent',ax)
        title(title_text,'fontsize',fst,'parent',ax)
        leg = legend('toggle');
        set(leg,'fontsize',14)
       
    otherwise
        fprintf('Selected plot type is not supported\n');
        
end