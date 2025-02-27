function [f_fit,plotHandle] = QuickLogFit(xdat,ydat,varargin)

defaults = cell(0,3); % 
% shared parameters for moving average
defaults(end+1,:) = {'plotOpts','cell',{'b-'}}; % separation distance considered contact. also used for window size at d_start
defaults(end+1,:) = {'showText','boolean',true};
defaults(end+1,:) = {'fitOffset','nonnegative',0};
pars = ParseVariableArguments(varargin,defaults,mfilename);

xdat = Column(xdat);
ydat = Column(ydat);

nG = length(xdat);
s = true(1,nG);
skip = isnan(ydat);
s(skip) = false;
f_fit = fit(log10(xdat(s)),log10(ydat(s)),'poly1');
plotHandle = plot(xdat(s),pars.fitOffset + 10.^f_fit(log10(xdat(s))),pars.plotOpts{:});
if pars.showText
    hold on;
    xx = nanmedian(xdat(s));
    yy = pars.fitOffset + 1.2*nanmedian(ydat(s));
    ft = ['a=',num2str(f_fit.p1,2)];
    text(xx,yy,ft);
end
