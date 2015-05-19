function p = getQueue(p)
%pds.eyelink.getQueue    get data samples from eyelink
%
% p = pds.eyelink.getQueue(p)
% pds.eyelink.getQueue pulls the values from the current Eyelink queue and
% puts them into the p.trial.eyelink struct
%
% 12/2013 jly   wrote it
% 2014    jk    adapted it for version 4.1
if p.trial.eyelink.use
    
    %get them all
    while ~p.trial.eyelink.drained
        if p.trial.eyelink.collectQueue
            [samplesIn,eventsIn, p.trial.eyelink.drained] = Eyelink('GetQueuedData');
        else
            sample=Eyelink('NewestFloatSample');
            if ~isstruct(sample)
                samplesIn=[];
            else
                samplesIn = [sample.time sample.type sample.flags sample.px sample.py sample.hx sample.hy sample.pa sample.gx sample.gy sample.rx sample.ry sample.status sample.input sample.buttons sample.htype sample.hdata]';
            end
            eventsIn = [];
            p.trial.eyelink.drained = true;
        end
        % Get Eyelink samples
        if ~isempty(samplesIn)
            p.trial.eyelink.samples(:,(p.trial.eyelink.sampleNum+1):p.trial.eyelink.sampleNum+size(samplesIn,2)) = samplesIn;
            p.trial.eyelink.sampleNum = p.trial.eyelink.sampleNum+size(samplesIn,2);
        end

        % Get Eyelink events
        if ~isempty(eventsIn)
            p.trial.eyelink.events(:,(p.trial.eyelink.eventNum+1):p.trial.eyelink.eventNum+size(eventsIn,2)) = eventsIn;
            p.trial.eyelink.eventNum = p.trial.eyelink.eventNum+size(eventsIn,2);
        end

        % Workaround - only continue if samplesIn and eventsIn were
        % empty
        if p.trial.eyelink.collectQueue && (~isempty(samplesIn) || ~isempty(eventsIn))
            p.trial.eyelink.drained = false;
        end

    end
    p.trial.eyelink.drained = false;
    
	if(p.trial.eyelink.useAsEyepos) 
        if p.trial.pldaps.eyeposMovAv > 1
           %should we warn in case of ~p.trial.eyelink.collectQueue?
           eInds=(p.trial.eyelink.sampleNum-p.trial.pldaps.eyeposMovAv+1):p.trial.eyelink.sampleNum;
           p.trial.eyeX = mean(p.trial.eyelink.samples(14,eInds));
           p.trial.eyeY = mean(p.trial.eyelink.samples(16,eInds));
        else
           p.trial.eyeX = p.trial.eyelink.samples(14,p.trial.eyelink.sampleNum);
           p.trial.eyeY = p.trial.eyelink.samples(16,p.trial.eyelink.sampleNum);
        end
	end
end