function p =  init(p)
% dv =  pds.Datapixx.init(dv)
% pdsDatapixxInit is a function that intializes the DATAPIXX, preparing it for
% experiments. Critically, the PSYCHIMAGING calls sets up the dual CLUTS
% (Color Look Up Table) for two screens.  These two CLUTS are in the
% dv.disp struct
% INPUTS
%       dv [struct] - main pldaps display variables structure
%           .disp [struct] - required display 
%               .ptr         - pointer to open PTB window
%               .useOverlay  - boolean for whether to use CLUT overlay
%               .gamma.table - required ( can be a linear gamma table )
%               .humanCLUT   [256 x 3] human color look up table
%               .monkeyCLUT  [256 x 3] monkey color look up table
% OUTPUTS
%       dv [modified]
%           .disp.overlayptr - pointer to overlay window added
%
%           if dv.useOverlay == 1, pdsDatapixxInit opens an overlay pointer
%           with dv.disp.monkeyCLUT as the color look up table for one
%           datapixx monitor and dv.disp.humanCLUT for the other monitor. 
%       
%       dv.disp.info - datapixx fields updated
% Datapixx is Opened and set to default settings for PLDAPS


% 2011       kme wrote it
% 12/03/2013 jly reboot for version 3


if p.defaultParameters.datapixx.use
    %the GPU needs an identity CLUT, at least on newer MACS, crashes
    %otherwiese
%     Screen('LoadNormalizedGammaTable',dv.defaultParameters.display.ptr,linspace(0,1,256)'*[1, 1, 1],0);
    
    if p.defaultParameters.display.useOverlay
        disp('****************************************************************')
        disp('****************************************************************')
        disp('Adding Overlay Pointer')
        disp('Combining color look up tables that can be found in')
        disp('dv.disp.humanCLUT and dv.disp.monkeyCLUT')
        disp('****************************************************************')

        combinedClut = [p.defaultParameters.display.humanCLUT ;p.defaultParameters.display.monkeyCLUT];
        %%% Gamma correction for dual CLUT %%%
        % check if gamma correction has been run on the window pointer
        if isField(p.defaultParameters, 'display.gamma.table')
            % get size of the combiend CLUT. It should be 512 x 3 (two 256 x 3 CLUTS
            % on top of eachother). 
            sc = size(combinedClut);

            % use sc to make a vector of 8-bit color steps from 0-1
            x = linspace(0,1,sc(1)/2);
            % use the gamma table to lookup what the values should be
            y = interp1(x,p.defaultParameters.display.gamma.table(:,1), combinedClut(:));
            % reshape the combined clut back to 512 x 3
            combinedClut = reshape(y, sc);
        end
        
        if p.defaultParameters.display.useOverlay==2 %debigging stuff
            % use sc to make a vector of 8-bit color steps from 0-1
            x = linspace(0,1,128);
            x_full = linspace(0,1,256);
            
            if isField(p.defaultParameters, 'display.gamma.table')
            	% use the gamma table to lookup what the values should be
                yr = interp1(x_full,p.defaultParameters.display.gamma.table(:,1), x);
                yg = interp1(x_full,p.defaultParameters.display.gamma.table(:,2), x);
                yb = interp1(x_full,p.defaultParameters.display.gamma.table(:,3), x);
                yrgb=[yr;yg;yb]';
            else
                yrgb=[x;x;x]';
            end
            % reshape the combined clut back to 512 x 3
%             combinedClut = reshape(y, sc);
            combinedClut=[yrgb; yrgb; yrgb ;repmat(p.defaultParameters.display.bgColor, [128 1])];
            
            p.defaultParameters.display.overlay.experimentorOnlyOffset = 0.5*256;
            p.defaultParameters.display.overlay.experimentorOnlyFactor = 0.5*256;
            
            p.defaultParameters.display.overlay.bothOffset = 0.0*256;
            p.defaultParameters.display.overlay.bothFactor = 0.5*256;
        end
    
        p.defaultParameters.display.overlayptr = PsychImaging('GetOverlayWindow', p.defaultParameters.display.ptr); % , dv.params.bgColor);
        % WARNING about LoadNormalizedGammaTable from Mario Kleiner: 
        % "Not needed, possibly harmful:
        % The PsychImaging() setup code already calls LoadIdentityClut() 
        % which loads a proper gamma table. Depending on operating system 
        % and gpu the tables need to differ a bit to compensate for driver 
        % bugs. The LoadIdentityClut routine knows a couple of different 
        % tables for different buggy systems. The automatic test code in 
        % BitsPlusIdentityClutTest and BitsPlusImagingPipelinetest also 
        % loads an identity lut via LoadIdentityClut and tests if that lut 
        % is working correctly for your gpu ? and tries to auto-fix that lut 
        % via an automatic optimization procedure if it isn?t correct. With 
        % your ?LoadNormalized?? command you are overwriting that optimal 
        % and tested lut, so you could add distortions to the video signal 
        % that is sent to the datapixx. A wrong lut could even erroneously 
        % trigger display dithering and add random imperceptible noise to 
        % the displayed image ? at least that is what i observed on my
        % MacBookPro with ati graphics under os/x 10.4.11.? 
        % (posted on Psychtoolbox forum, 3/9/2010) 
        % 
        % We don't seem to have this problem - jake 12/04/13
        Screen('LoadNormalizedGammaTable', p.defaultParameters.display.ptr, combinedClut, 2);
    end
    
    p.defaultParameters.datapixx.info.DatapixxFirmwareRevision = Datapixx('GetFirmwareRev'); 
    p.defaultParameters.datapixx.info.DatapixxRamSize = Datapixx('GetRamSize');
    
    
    %%% Open Datapixx and get ready for data aquisition %%%
    Datapixx('Open');
    Datapixx('StopAllSchedules');
    Datapixx('DisableDinDebounce');  
    Datapixx('EnableAdcFreeRunning');
    Datapixx('SetDinLog');            
    Datapixx('StartDinLog'); 
    Datapixx('SetDoutValues',0);
    Datapixx('RegWrRd');    
    
    %start adc data collection if requested
    pds.datapixx.adc.start(p);
else
    if p.defaultParameters.display.useOverlay
        %TODO: 
        % 1: throw error unless some debug variable is set
        % 2: have switch to either to this or make overlaypointer a pointer
        % to an invisible window or a second one.
%         a1=Screen('ReadNormalizedGammaTable',1,1);
%         a2=Screen('ReadNormalizedGammaTable',2,1);
%         
%         
%         Screen('LoadNormalizedGammaTable', 1, a2,0);
%         Screen('LoadNormalizedGammaTable', 2, a2,0);
%        
%         
%         a1=Screen('ReadNormalizedGammaTable',1,1);
%         a2=Screen('ReadNormalizedGammaTable',2,1);
%         a2(:,3)=0;
%         
%         Screen('LoadNormalizedGammaTable', 1, a1, 0,1);
%         Screen('LoadNormalizedGammaTable', 2, a2, 0, 1);        
%         
%         b1=Screen('ReadNormalizedGammaTable',1,1);
%         b2=Screen('ReadNormalizedGammaTable',2,1);

%             dv.defaultParameters.display.overlay.experimentorOnlyOffset = dv.defaultParameters.display.bgColor(1); %TODO allow non gray bgColor
%             dv.defaultParameters.display.overlay.experimentorOnlyFactor = 0.0*256;
%             
%             dv.defaultParameters.display.overlay.bothOffset = 0.0;
%             dv.defaultParameters.display.overlay.bothFactor = 1*256;

        warning('pldaps:datapixxInit','Overlay requested, but not Datapixx disabled. Assuming debug scenario. Will assign ptr to overlayptr');
        p.defaultParameters.display.overlayptr = p.defaultParameters.display.ptr;
    end

end