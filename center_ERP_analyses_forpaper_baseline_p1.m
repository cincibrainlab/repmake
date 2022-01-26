clear all;

%controls matched to final count fxs
controls=['0199_hab_ICAb_av.dat';	'0221_hab_ICAb_av.dat';	'0232_hab_ICAb_av.dat';'0255_hab_ICAb_av.dat';'0565_hab_ICAb_av.dat';'0743_hab_ICAb_av.dat';'0750_hab_ICAb_av.dat';'0753_hab_ICAb_av.dat';'0755_hab_ICAb_av.dat';'0827_hab_ICAb_av.dat';'0964_hab_ICAb_av.dat';'0979_hab_ICAb_av.dat';'1178_hab_ICAb_av.dat';'1259_hab_ICAb_av.dat';'1321_hab_ICAb_av.dat';'1401_hab_ICAb_av.dat';'1409_hab_ICAb_av.dat';'1458_hab_ICAb_av.dat';'1486_hab_ICAb_av.dat';	'1622_hab_ICAb_av.dat'; 
    '1791_hab_ICAb_av.dat';'1966_hab_ICAb_av.dat';'2058_hab_ICAb_av.dat';'2066_hab_ICAb_av.dat';'2150_hab_ICAb_av.dat';'2262_hab_ICAb_av.dat';'2274_hab_ICAb_av.dat';'2278_hab_ICAb_av.dat';'2331_hab_ICAb_av.dat';'2370_hab_ICAb_av.dat';'2701_hab_ICAb_av.dat';'2724_hab_ICAb_av.dat';'2730_hab_ICAb_av.dat';'2804_hab_ICAb_av.dat';'2863_hab_ICAb_av.dat';'3226_hab_ICAb_av.dat';'3246_hab_ICAb_av.dat';'3423_hab_ICAb_av.dat';];
%subs_gen=['0755_hab_ICAb_av.generic';	'1175_hab_ICAb_av.generic';	'1259_hab_ICAb_av.generic';	'1618_hab_ICAb_av.generic'; '2066_hab_ICAb_av.generic';'3226_hab_ICAb_av.generic';'3423_hab_ICAb_av.generic';'1401_hab_ICAb_av.generic';'1791_hab_ICAb_av.generic';];

%fxs all
fxs=['0179_hab_ICAb_av.dat';'0320_hab_ICAb_av.dat';'0366_hab_ICAb_av.dat';'0455_hab_ICAb_av.dat';'0536_hab_ICAb_av.dat';'0838_hab_ICAb_av.dat';'0918_hab_ICAb_av.dat';'1140_hab_ICAb_av.dat';'1141_hab_ICAb_av.dat';	'1327_hab_ICAb_av.dat';	'1356_hab_ICAb_av.dat';'1556_hab_ICAb_av.dat';'1572_hab_ICAb_av.dat';	'1806_hab_ICAb_av.dat';'1875_hab_ICAb_av.dat';'2210_hab_ICAb_av.dat';'2246_hab_ICAb_av.dat';'2302_hab_ICAb_av.dat';'2417_hab_ICAb_av.dat';'2438_hab_ICAb_av.dat';
    '2464_hab_ICAb_av.dat';'2530_hab_ICAb_av.dat';'2709_hab_ICAb_av.dat';'3140_hab_ICAb_av.dat';'3155_hab_ICAb_av.dat';'3160_hab_ICAb_av.dat';'3301_hab_ICAb_av.dat';'3325_hab_ICAb_av.dat';'3417_hab_ICAb_av.dat';'3478_hab_ICAb_av.dat';];
%subs_gen=['0366_hab_ICAb_av.generic';	'0455_hab_ICAb_av.generic';	'1327_hab_ICAb_av.generic';	'1572_hab_ICAb_av.generic';	'1806_hab_ICAb_av.generic';'2438_hab_ICAb_av.generic';'2464_hab_ICAb_av.generic';'3301_hab_ICAb_av.generic';];
%weights(:,1)=load('Hab_ALL_adults_weight1.asc');
%weights=weights.*-1;


%FXSN1_1=[106 98 92 86 94 100 98 88 108 90 104 106 112 100];
%FXSN1_2=[628 616 610 612 610 620 612 604 624 612 624 620 632 620];
%FXSN1_3=[1144 1134 1138 1128 1136 1138 1136 1124 1142 1140 1144 1144 1154 1136];
%FXSN1_4=[1666 1656 1656 1650 1658 1656 1658 1646 1672 1656 1666 1670 1680 1660];

%CONN1_1=[96 94 96 90 96 86 86 86 88 114 88 94 98 102 94 ];
%CONN1_2=[610 606 628 612 610 640 606 610 618 658 614 618 616 622 612 ];
%CONN1_3=[1136 1132 1142 1130 1138 1132 1128 1132 1150 1134 1128 1140 1140 1146 1138 ];
%CONN1_4=[1654 1654 1662 1654 1662 1656 1656 1652 1652 1704 1654 1662 1660 1668 1654 ];

%FXSP2_1=[188 182 176 192 188 182 188 164 176 162 192 188 202 208];
%FXSP2_2=[706 700 696 774 696 698 732 668 700 720 710 702 696 736];
%FXSP2_3=[1212 1220 1220 1202 1216 1220 1206 1188 1214 1234 1234 1216 1218 1256];
%FXSP2_4=[1746 1738 1738 1726 1738 1734 1756 1730 1740 1756 1748 1750 1740 1778];

%CONP2_1=[164 178 186 162 164 190 158 150 210 208 176 184 186 178 214];
%CONP2_2=[686 690 682 680 676 712 682 650 750 714 704 704 704 700 738];
%CONP2_3=[1194 1208 1234 1200 1206 1242 1178 1184 1270 1240 1234 1230 1228 1220 1270];
%CONP2_4=[1702 1736 1744 1720 1722 1758 1724 1696 1764 1770 1750 1712 1752 1740 1776];
% 
% ASDN1_1=[88 90 104 88 114 100 120 128];
% ASDN1_2=[606 606 610 606 748 618 648 656];
% ASDN1_3=[1128 1128 1132 1128 1288 1142 1154 1120];
% ASDN1_4=[1648 1650 1666 1648 1818 1662 1662 1644];

   for n=1:38
        fid=fopen('2274_hab-ST.dat','r');
        data4=fread(fid,[129 1500],'float');
        fclose(fid);
        clear dat1;
%     for t=1:1500;
%         tmp=mean(data1(:,t).*weights(:,1));
%         dat1(1,t)=tmp/mean(weights(:,1).^2);
%          %tmp=mean(data1(:,t).*weights(:,2));
%         %dat2(1,t)=tmp/mean(weights(:,2).^2);
%     end
    dat1=(data4(7,:)+data4(13,:)+data4(6,:)+data4(112,:)+data4(106,:)+data4(12,:)+data4(20,:)+data4(29,:)+data4(118,:)+data4(5,:)+data4(19,:)+data4(11,:)+data4(4,:)+data4(24,:)+data4(28,:)+data4(36,:)+data4(124,:)+data4(117,:)+data4(111,:)+data4(3,:)+data4(10,:)+data4(16,:)+data4(18,:)+data4(23,:))/24;
    controls2(n,:)=dat1;
    end
    controls_mean=mean(controls2,1);
    
    for n=1:30
        fid=fopen(fxs(n,:),'r');
        data4=fread(fid,[129 1500],'float');
        fclose(fid);
%     for t=1:1500;
%         tmp=mean(data1(:,t).*weights(:,1));
%         dat1(1,t)=tmp/mean(weights(:,1).^2);
%          %tmp=mean(data1(:,t).*weights(:,2));
%         %dat2(1,t)=tmp/mean(weights(:,2).^2);
%     end
    dat1=(data4(7,:)+data4(13,:)+data4(6,:)+data4(112,:)+data4(106,:)+data4(12,:)+data4(20,:)+data4(29,:)+data4(118,:)+data4(5,:)+data4(19,:)+data4(11,:)+data4(4,:)+data4(24,:)+data4(28,:)+data4(36,:)+data4(124,:)+data4(117,:)+data4(111,:)+data4(3,:)+data4(10,:)+data4(16,:)+data4(18,:)+data4(23,:))/24;
    fxs2(n,:)=dat1;
    end
    fxs_mean=mean(fxs2,1);

%     for n=1:8
%         fid=fopen(asd(n,:),'r');
%         data1=fread(fid,[128 1500],'float');
%         fclose(fid);
%     for t=1:1500;
%         tmp=mean(data1(:,t).*weights(:,1));
%         dat1(1,t)=tmp/mean(weights(:,1).^2);
%          %tmp=mean(data1(:,t).*weights(:,2));
%         %dat2(1,t)=tmp/mean(weights(:,2).^2);
%     end
%     asd2(n,:)=dat1;
%     end
%     asd_mean=mean(asd2,1);
 xaxis=[-500:2:2498];   
figure; plot(xaxis,fxs_mean,'r');
hold
%plot(asd_mean,'b');
plot(xaxis,controls_mean,'k');

figure; plot(fxs_mean,'r');
hold
%plot(asd_mean,'b');
plot(controls_mean,'k');

for subs=1:38
for t=1:300;
          cbins(subs,t)=mean(controls2(subs,(((t-1)*5)+1):(t*5))); %#ok<*SAGROW> 
        end
end

for subs=1:30
for t=1:300;
          fbins(subs,t)=mean(fxs2(subs,(((t-1)*5)+1):(t*5)));
        end
end

% for subs=1:8
% for t=1:300;
%           abins(subs,t)=mean(asd2(subs,(((t-1)*5)+1):(t*5)));
%         end
% end


for tt=1:300
    group1=cbins(:,tt);
    group2=fbins(:,tt);
[h,p,ci,stats]=ttest2(group1,group2);
pbar_bins(1,tt)=p;
tbar_bins(1,tt)=stats.tstat;
end
figure; imagesc(pbar_bins);

for n=1:21
    FXSP2(n,1)=fxs2(n,(FXSP2_1(1,n))/2+250);
    FXSP2(n,2)=fxs2(n,(FXSP2_2(1,n))/2+250);
    FXSP2(n,3)=fxs2(n,(FXSP2_3(1,n))/2+250);
    FXSP2(n,4)=fxs2(n,(FXSP2_4(1,n))/2+250);
end

for n=1:24
    CONP2(n,1)=controls2(n,(CONP2_1(1,n))/2+250);
    CONP2(n,2)=controls2(n,(CONP2_2(1,n))/2+250);
    CONP2(n,3)=controls2(n,(CONP2_3(1,n))/2+250);
    CONP2(n,4)=controls2(n,(CONP2_4(1,n))/2+250);
end

% for n=1:8
%     ASDN1(n,1)=asd2(n,(ASDN1_1(1,n))/2+250);
%     ASDN1(n,2)=asd2(n,(ASDN1_2(1,n))/2+250);
%     ASDN1(n,3)=asd2(n,(ASDN1_3(1,n))/2+250);
%     ASDN1(n,4)=asd2(n,(ASDN1_4(1,n))/2+250);
% end

% habfxs(:,1)=(FXSN1(:,1)-FXSN1(:,2))./FXSN1(:,1);
% habfxs(:,2)=(FXSN1(:,1)-FXSN1(:,3))./FXSN1(:,1);
% habfxs(:,3)=(FXSN1(:,1)-FXSN1(:,4))./FXSN1(:,1);
% 
% % habASD(:,1)=(ASDN1(:,1)-ASDN1(:,2))./ASDN1(:,1);
% % habASD(:,2)=(ASDN1(:,1)-ASDN1(:,3))./ASDN1(:,1);
% % habASD(:,3)=(ASDN1(:,1)-ASDN1(:,4))./ASDN1(:,1);
% 
% habCON(:,1)=(CONN1(:,1)-CONN1(:,2))./CONN1(:,1);
% habCON(:,2)=(CONN1(:,1)-CONN1(:,3))./CONN1(:,1);
% habCON(:,3)=(CONN1(:,1)-CONN1(:,4))./CONN1(:,1);
% 

for n=1:30
fxsN1(n,1)=min(fxs2(n,276:316));
fxsN1(n,2)=min(fxs2(n,532:572));
fxsN1(n,3)=min(fxs2(n,789:829));
fxsN1(n,4)=min(fxs2(n,1049:1089));
end

for n=1:30
[min_num,min_ind]=min(fxs2(n,276:316));
fxsN1lat(n,1)=min_ind;
[min_num,min_ind]=min(fxs2(n,532:572));
fxsN1lat(n,2)=min_ind;
[min_num,min_ind]=min(fxs2(n,789:829));
fxsN1lat(n,3)=min_ind;
[min_num,min_ind]=min(fxs2(n,1049:1089));
fxsN1lat(n,4)=min_ind;
end

for n=1:38
controlsN1(n,1)=min(controls2(n,276:316));
controlsN1(n,2)=min(controls2(n,532:572));
controlsN1(n,3)=min(controls2(n,789:829));
controlsN1(n,4)=min(controls2(n,1049:1089));
end

for n=1:38
[min_num,min_ind]=min(controls2(n,276:316));
conN1lat(n,1)=min_ind;
[min_num,min_ind]=min(controls2(n,532:572));
conN1lat(n,2)=min_ind;
[min_num,min_ind]=min(controls2(n,789:829));
conN1lat(n,3)=min_ind;
[min_num,min_ind]=min(controls2(n,1049:1089));
conN1lat(n,4)=min_ind;
end

for n=1:30
fxsP2(n,1)=max(fxs2(n,316:356));
fxsP2(n,2)=max(fxs2(n,575:615));
fxsP2(n,3)=max(fxs2(n,835:875));
fxsP2(n,4)=max(fxs2(n,1093:1133));
end

for n=1:30
[min_num,min_ind]=max(fxs2(n,316:356));
fxsP2lat(n,1)=min_ind;
[min_num,min_ind]=max(fxs2(n,575:615));
fxsP2lat(n,2)=min_ind;
[min_num,min_ind]=max(fxs2(n,835:875));
fxsP2lat(n,3)=min_ind;
[min_num,min_ind]=max(fxs2(n,1093:1133));
fxsP2lat(n,4)=min_ind;
end

for n=1:38
controlsP2(n,1)=max(controls2(n,316:356));
controlsP2(n,2)=max(controls2(n,575:615));
controlsP2(n,3)=max(controls2(n,835:875));
controlsP2(n,4)=max(controls2(n,1093:1133));
end

for n=1:38
[min_num,min_ind]=max(controls2(n,316:356));
conP2lat(n,1)=min_ind;
[min_num,min_ind]=max(controls2(n,575:615));
conP2lat(n,2)=min_ind;
[min_num,min_ind]=max(controls2(n,835:875));
conP2lat(n,3)=min_ind;
[min_num,min_ind]=max(controls2(n,1093:1133));
conP2lat(n,4)=min_ind;
end

[h,p,ci,stats]=ttest2(fxsN1(:,1),controlsN1(:,1));
[h,p,ci,stats]=ttest2(fxsN1(:,2),controlsN1(:,2));
[h,p,ci,stats]=ttest2(fxsN1(:,3),controlsN1(:,3));
[h,p,ci,stats]=ttest2(fxsN1(:,4),controlsN1(:,4));

N1_pc_fxs(:,1)=(((fxsN1(:,1)-fxsN1(:,2))))./fxsN1(:,1);
N1_pc_fxs(:,2)=(((fxsN1(:,1)-fxsN1(:,3))))./fxsN1(:,1);
N1_pc_fxs(:,3)=(((fxsN1(:,1)-fxsN1(:,4))))./fxsN1(:,1);

N1_pc_con(:,1)=(((controlsN1(:,1)-controlsN1(:,2))))./controlsN1(:,1);
N1_pc_con(:,2)=(((controlsN1(:,1)-controlsN1(:,3))))./controlsN1(:,1);
N1_pc_con(:,3)=(((controlsN1(:,1)-controlsN1(:,4))))./controlsN1(:,1);

[h,p,ci,stats]=ttest2(N1_pc_fxs(:,1),N1_pc_con(:,1));
[h,p,ci,stats]=ttest2(N1_pc_fxs(:,2),N1_pc_con(:,2));
[h,p,ci,stats]=ttest2(N1_pc_fxs(:,3),N1_pc_con(:,3));

[h,p,ci,stats]=ttest2(fxsP2(:,1),controlsP2(:,1));
[h,p,ci,stats]=ttest2(fxsP2(:,2),controlsP2(:,2));
[h,p,ci,stats]=ttest2(fxsP2(:,3),controlsP2(:,3));
[h,p,ci,stats]=ttest2(fxsP2(:,4),controlsP2(:,4));

allhabfxs=(mean(habfxs,2));
allhabcon=mean(habCON,2);
[h,p,ci,stats]=ttest2(allhabfxs,allhabcon);



% N1_pc_fxs(:,1)=(((fxs2(:,298)-fxs2(:,552))))./fxs2(:,298);
% N1_pc_fxs(:,2)=(((fxs2(:,298)-fxs2(:,816))))./fxs2(:,298);
% N1_pc_fxs(:,3)=(((fxs2(:,298)-fxs2(:,1076))))./fxs2(:,298);
% 
% N1_pc_con(:,1)=(((controls2(:,302)-controls2(:,561))))./controls2(:,302);
% N1_pc_con(:,2)=(((controls2(:,302)-controls2(:,823))))./controls2(:,302);
% N1_pc_con(:,3)=(((controls2(:,302)-controls2(:,1079))))./controls2(:,302);
% 

% N1_pc_asd(:,1)=(((asd2(:,298)-asd2(:,558))))./asd2(:,298);
% N1_pc_asd(:,2)=(((asd2(:,298)-asd2(:,820))))./asd2(:,298);
% N1_pc_asd(:,3)=(((asd2(:,298)-asd2(:,1080))))./asd2(:,298);

% [h,p,ci,stats]=ttest2(N1_pc_fxs(:,3),N1_pc_con(:,3));
% 
% 
% P2_pc_con(:,1)=(((controls2(:,347)-controls2(:,605))))./controls2(:,347);
% P2_pc_con(:,2)=(((controls2(:,347)-controls2(:,869))))./controls2(:,347);
% P2_pc_con(:,3)=(((controls2(:,347)-controls2(:,1127))))./controls2(:,347);
% 
% P2_pc_asd(:,1)=(((asd2(:,347)-asd2(:,605))))./asd2(:,347);
% P2_pc_asd(:,2)=(((asd2(:,347)-asd2(:,869))))./asd2(:,347);
% P2_pc_asd(:,3)=(((asd2(:,347)-asd2(:,1127))))./asd2(:,347);
% 
% [h,p,ci,stats]=ttest2(P2_pc_con(:,1),P2_pc_prem(:,1));
% 
% N1_pc_prem(:,1)=(((prem2(:,298)-prem2(:,558))))./prem2(:,298);
% N1_pc_prem(:,2)=(((prem2(:,298)-prem2(:,819))))./prem2(:,298);
% N1_pc_prem(:,3)=(((prem2(:,298)-prem2(:,1080))))./prem2(:,298);
% 
% P2_pc_prem(:,1)=(((prem2(:,347)-prem2(:,605))))./prem2(:,347);
% P2_pc_prem(:,2)=(((prem2(:,347)-prem2(:,869))))./prem2(:,347);
% P2_pc_prem(:,3)=(((prem2(:,347)-prem2(:,1127))))./prem2(:,347);

%pull N2 bins for stats
FXS_N2(:,1)=mean(fbins(:,80:83),2);
FXS_N2(:,2)=mean(fbins(:,134:135),2);
FXS_N2(:,3)=mean(fbins(:,184:189),2);
FXS_N2(:,4)=mean(fbins(:,236:239),2);

CON_N2(:,1)=mean(cbins(:,80:83),2);
CON_N2(:,2)=mean(cbins(:,134:135),2);
CON_N2(:,3)=mean(cbins(:,184:189),2);
CON_N2(:,4)=mean(cbins(:,236:239),2);



