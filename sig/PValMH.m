function [qFDR_tophits, pa, pval_tophits,mfull] = PValMH(mfull, p, bins, events, sij1dx, chsize, CHR, approx_flag)

qqplot_flag = 1;

% general variables
mat_size = size(mfull);

wga=sum(chsize(CHR));
density_area=zeros(length(sij1dx),1);
for c1=1:length(sij1dx)-1
    for c2=CHR,
        if (chsize(c2)-sij1dx(c1))>0
            if (chsize(c2)-sij1dx(c1+1))>0
                density_area(c1)=density_area(c1)+sqrt(2)*(2*chsize(c2)-sij1dx(c1)-sij1dx(c1+1))*(sij1dx(c1+1)-sij1dx(c1));
            else
                density_area(c1)=density_area(c1)+(chsize(c2)-sij1dx(c1))^2/2;
            end
        end
    end
end
for c2=CHR,
     density_area(length(sij1dx))=density_area(length(sij1dx))+(wga-chsize(c2))*chsize(c2);
end
intra_events=events(:,1)==events(:,4);
events_length=abs(events(intra_events,5)-events(intra_events,2));
for c1=1:length(sij1dx)-1
    event_count(c1)=sum(events_length>=sij1dx(c1)&events_length<sij1dx(c1+1));
    e_density(c1)=event_count(c1)/density_area(c1)*1e12;
end
event_count(length(sij1dx))=sum(events(:,1)~=events(:,4));
e_density(length(sij1dx))=event_count(length(sij1dx))/density_area(length(sij1dx));

% keep only upper diagonal part of mfull 
mfull = triu(full(mfull));
mfull(eye(mat_size)~=0) = diag(mfull)/2;
nume = sum(mfull(:));

% probability matrix
pa=p;
if issymmetric(p)
    pa=triu(p);
    pa(eye(mat_size)~=0) = diag(pa)/2;
end

    
% divide tiles with positive values from zeros 
high_k = find(mfull>=2 & pa>0);
pos_k = find(mfull==1 & pa>0);
zero_k = find(mfull==0 & pa>0);
mfull_pos = full(mfull(pos_k));
mfull_high = full(mfull(high_k));
p_high = pa(high_k);
p_pos = pa(pos_k);
p_zero = pa(zero_k);


% p-vals 
disp(['calculating p-val for ' num2str(length(zero_k)) ' tiles with zero events']);
tic
if ~approx_flag
    pval_low=1-(1-p_zero).^nume.*rand(length(zero_k),1);
else
    pval_low=1-exp(-p_zero*nume).*rand(length(zero_k),1);
end
toc

disp(['calculating p-val for ' num2str(length(pos_k)) ' tiles with 1 event']);
rand_nnz = rand(length(pos_k),1);
tic
if ~approx_flag
    pval_pos = binopdf(mfull_pos, nume, p_pos).*rand_nnz+(1-binocdf(mfull_pos,nume,p_pos));
else
    pval_pos = poisspdf(mfull_pos, nume*p_pos).*rand_nnz+(1-poisscdf(mfull_pos,nume*p_pos));
end
toc

disp(['calculating support for ' num2str(length(high_k)) ' tiles with >1 events']);
tic
t_dv=zeros(length(high_k),1);

for c1=1:length(high_k)
    [a1, a2]=ind2sub(mat_size,high_k(c1));
    if abs(a1-a2)>2
        t_d=tile_density( [a1 a2], bins, events, sij1dx, e_density, 0 );
        t_dv(c1)=t_d(1)/(bins(a1,3)-bins(a1,2))/(bins(a2,3)-bins(a2,2));
    else
        t_dv(c1)=2;
    end
end
t_dv(t_dv>2)=2;
t_dv(t_dv<0.1)=0.1;
p_high_s=p_high.*t_dv;

%p_high_s=p_high;
toc
disp(['calculating p-val for ' num2str(length(high_k)) ' tiles with >1 events']);
tic
rand_nnz = rand(length(high_k),1);

if ~approx_flag
%    pval_high = binopdf(mfull_high, nume, p_high).*rand_nnz+(1-binocdf(mfull_high,nume,p_high));
else
%    pval_high = poisspdf(mfull_high, nume*p_high_s).*rand_nnz+(1-poisscdf(mfull_high,nume*p_high_s));
%     mult_a=100;
%     l_ones=ones(mult_a,1);
%     for c3=1:length(mfull_high),
%         if t_dv(c3)<1,            
%             pval_high(c3,1) = sum(mnpdf([nume*l_ones-(mfull_high(c3)+1:mfull_high(c3)+mult_a)' (mfull_high(c3)+1:mfull_high(c3)+mult_a)' 0*l_ones],kron([1-p_high(c3) p_high_s(c3) p_high(c3)-p_high_s(c3)],l_ones)));
%         else
%             pval_high(c3,1) = binopdf(mfull_high(c3), nume, p_high_s(c3)).*rand_nnz(c3)+(1-binocdf(mfull_high(c3),nume,p_high_s(c3)));
%         end
%     end
    pval_high = binopdf(mfull_high, nume, p_high_s).*rand_nnz+(1-binocdf(mfull_high,nume,p_high_s));
    pval_high0 = (1-binocdf(mfull_high-1,nume,p_high_s));
end
toc

pval=[pval_low zero_k;pval_pos pos_k;pval_high high_k];
pval_high0=[pval_high0 high_k];

% qq-plot  
if qqplot_flag
   qqplot(pval(:,1),[]);
end

% calcualte BH-FDR
qFDR=mafdr(pval(:,1),'BHFDR','true');
hits_idx=(qFDR<0.1);
%tophits=sum(hits_idx);
tophits = sortrows([pval(hits_idx,:) qFDR(hits_idx)],1);
[p_high_b,p_high_loc]=ismember(tophits(:,2),pval_high0(:,2));

max_th=max(tophits(:,1));
hits_to_remove=zeros(length(tophits),1);
for c1=1:length(tophits)
    if p_high_b(c1)==1 && pval_high0(p_high_loc(c1),1)>max_th
        hits_to_remove(c1)=1;
    end
end
tophits(logical(hits_to_remove),:)=[];

pval_tophits=tophits(:,1:2);
qFDR_tophits=tophits(:,3);

return

