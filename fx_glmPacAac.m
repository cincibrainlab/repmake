function [glmResults] = fx_glmPacAac( si, loBandArr, hiBandArr, bandDefs, cEEG)
count = 1;
chanlocs = cEEG.chanlocs;

glmres = zeros( numel(loBandArr)*length(chanlocs)*length(chanlocs), ...
    numel(loBandArr)*length(chanlocs)*length(chanlocs));
 
    for lobandi = 1 : length(bandDefs)
        bandname =[ bandDefs{lobandi,1} ];
        if contains(bandname, loBandArr) % low to high frequency
            lowerband = bandname;
            locutoff = bandDefs{lobandi,2};
            hicutoff = bandDefs{lobandi,3};
            Vlo = fx_eegfilt(cEEG.srate, locutoff, hicutoff, cEEG.data); %#ok<*NASGU> % continuous EEG

            for upbandi = 1 : length(bandDefs)
                upbandname = bandDefs{upbandi,1};
                if contains(upbandname, hiBandArr) % low to high frequency ,'gamma2','epsilon'
                    glmname = [lowerband '_' upbandname];
                    ulocutoff = bandDefs{upbandi,2};
                    uhicutoff = bandDefs{upbandi,3};
                    Vhi = fx_eegfilt(cEEG.srate, ulocutoff, uhicutoff, cEEG.data); %#ok<*NASGU> % continuous EEG

                    channo = size(Vhi,2);
                    glmResults.(glmname) = cell(channo,channo);
                    for ei = 1 : channo
                        for ei2 = 1 : channo
                            %count = count + 1;
                            fprintf("%s Si: %d VLo: %d: VHi: %d\n",  glmname, si, ei,ei2)
                            %[XX,P] = glmfun(Vlo(:,ei)', Vhi(:,ei2)', 'theoretical','ci');
                            [XX,P] = glmfun(Vlo(:,ei)', Vhi(:,ei2)');

                            % try, XX.P = P; catch; end;
                            glmResults.(glmname){ei,ei2} = XX;
                            %   glmaac.(glmname)(ei,ei2) = XX.raac;
                            %  glmpac.(glmname)(ei,ei2) = XX.rpac; %count;
                        end
                    end
                end
            end
        end
    end
       
end