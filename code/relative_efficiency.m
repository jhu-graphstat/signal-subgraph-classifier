%% synthetic
clear, clc

% constants
V=70;

% signal subgraph
m=1;
s=20;
Ess = 2:s+1;

% parameters
p=0.1;
q=0.3;

% parameters
E0=p*ones(V);
E1=p*ones(V);
E1(Ess)=q;

fname=['RE_V' num2str(V) '_s' num2str(s) '_p' num2str(round(p*100)) '_q' num2str(round(q*100))];

%% simulate data for coherogram plots
clear h SigMat coherent incoherent coherogram Coherogram wset


ns=[10 20 30 40 50 100:100:500 1000 2000];
nTrials=200*ones(1,numel(ns));
% nTrials(1)=100;
 
inc_cor = nan(length(ns),1);
coh_cor = inc_cor;

for i=1:length(ns)
    
    disp(['nTrials = ' num2str(ns(i))])
    
    
    parfor t=1:nTrials(i)
        
        % training data
        ntrn=ns(i);
        Atrn = nan(V,V,ntrn);
        Atrn(:,:,1:2:ntrn)=repmat(E0,[1 1 ntrn/2]) > rand(V,V,ntrn/2);
        Atrn(:,:,2:2:ntrn)=repmat(E1,[1 1 ntrn/2]) > rand(V,V,ntrn/2);
        for nn=1:ntrn, Atrn(:,:,nn)=tril(Atrn(:,:,nn),-1); end
        ytrn=repmat([0 1],1,ntrn/2);
        
        constants   = get_constants(Atrn,ytrn);     % get constants to ease classification code
        SigMat      = get_fisher(Atrn,constants);
        incoherent  = signal_subgraph_estimator(SigMat,s);
        coherent    = signal_subgraph_estimator(SigMat,[m s]);
        
%         incoherent = incoherent_estimator(SigMat,s);
%         [coherent cocount]= coherent_estimator(SigMat,m,s);
        
        inc_cor(i,t) = length(intersect(incoherent,Ess));
        coh_cor(i,t) = length(intersect(coherent,Ess));
        
    end
end

%% get stats
inc_avg=1-mean(inc_cor,2)/s;
coh_avg=1-mean(coh_cor,2)/s;

inc_ste=mad(inc_cor',1)./sqrt(nTrials);
coh_ste=mad(coh_cor',1)./sqrt(nTrials);

rel_cor=(inc_cor)./(coh_cor);

RE_avg=(1-inc_avg)./(1-coh_avg);
RE_ste=mad(RE_avg',1)./sqrt(nTrials);

% relative efficiency
xi=[4:10:max(ns)]';
cohi = interp1q(ns',coh_avg,xi);

for i=1:length(ns)
    temp=xi(find(cohi<inc_avg(i),1))/ns(i);
    if ~isempty(temp), re(i)=temp; else, re(i)=1; end
end

%%
savestuff=0;
if savestuff==1
    save(['../../data/' fname])
end


%% get stats

% load(['../../data/results/' fname])

q=find(isfinite(RE_avg), 1 );


figure(V), clf, clear h
grays=linspace(0,0.75,length(ns));
gray1=0.5*[1 1 1];
sa=0.5;
fs=12;

h(1)=subplot(311);
hold all
errorbar(ns(1:end-2),inc_avg(1:end-2),inc_ste(1:end-2)./sqrt(nTrials(1:end-2)),'-','linewidth',2,'color',gray1)
errorbar(ns(1:end-2),coh_avg(1:end-2),coh_ste(1:end-2)./sqrt(nTrials(1:end-2)),'-','linewidth',2,'color','k')
% title('edges','fontsize',fs)
ylabel('missed edge rate','fontsize',fs)
% xlabel('# training samples','fontsize',fs)
lh=legend('incoherent','coherent');
axis('tight')
set(lh,'Location','NorthEast','fontsize',fs)
axis([0 ns(end-2) 0 1])
set(gca,'fontsize',fs)
% xticks=[3 8 9];
set(gca,'XTick',100:100:500)

h(2)=subplot(312); hold all
errorbar(ns(1:end-2),RE_avg(1:end-2),RE_ste(1:end-2),'-','linewidth',2,'color','k')
plot([0 ns(end-2)],[1 1],'--k')
ylabel('relative rate','fontsize',fs)
% xlabel('# training samples','fontsize',fs)
axis('tight')
set(gca,'XTick',100:100:500)
% set(gca,'XTick',ns(xticks))
% xlim([ns(1) max(ns(xticks))])
% axis([0 max(ns) min(RE_avg-RE_ste') 2])
set(h(2),'yscale','log')
set(gca,'YTick',[0.1 1 10],'YTickLabel',[0.1 1 10])

h(3)=subplot(313); hold all
plot(ns,re,'k','linewidth',2)
plot([0 max(ns)],[1 1],'--k')
ylabel(' relative efficiency','fontsize',fs)
xlabel('# training samples','fontsize',fs)
% set(gca,'XTick',200:200:ns(end))
sre=sort(re);
% yticks=[0.8 1 2 4 6];
% set(gca,'YTick',yticks,'YTickLabel',round(10*yticks)/10)
% set(gca,'YScale','log')
% ylim([min(re)-0.1 max(re)+0.1])
set(gca,'XTick',200:200:1000)
xlim([0 1000])
% axis([0 max(ns) 0.8 6])
set(h,'fontsize',fs)
% linkaxes(h,'x')

%%
if savestuff==1
    print_fig(['../../figs/' fname],[2 2.5]*2)
end
