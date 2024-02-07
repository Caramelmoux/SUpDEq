%demo_SOFAmerge - This demo shows how to use SOFAmerge.
% It requires the TU-Berlin KEMAR HRTFs for different radii in the SOFA
% directory. These files can be generated by demo_TUBerlin2SOFA
 
% #Author: Piotr Majdak
% #Author: Michael Mihocic: bugs fixed (10.2021)
% #Author: Michael Mihocic: header documentation updated (28.10.2021)
% 
% SOFA Toolbox - demo script
% Copyright (C) Acoustics Research Institute - Austrian Academy of Sciences
% Licensed under the EUPL, Version 1.2 or � as soon they will be approved by the European Commission - subsequent versions of the EUPL (the "License")
% You may not use this work except in compliance with the License.
% You may obtain a copy of the License at: https://joinup.ec.europa.eu/software/page/eupl
% Unless required by applicable law or agreed to in writing, software distributed under the License is distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
% See the License for the specific language governing  permissions and limitations under the License. 



%% Define parameters
% Prefix to the files 
TUBfile = 'qu_kemar_anechoic_';
% Define vector with radii to be merged. Available files: 0.5, 1, 2, and 3 m
radius=[0.5 1 2 3]; 

% Data compression (0..uncompressed, 9..most compressed)
compression=1; % results in a nice compression within a reasonable processing time

%% Load the objects to be merged
clear Obj;
for ii=1:length(radius)
	sourcefn=fullfile(SOFAdbPath, 'database', 'tu-berlin', [TUBfile num2str(radius(ii)) 'm.sofa']);
	disp(['Loading: ' sourcefn]);
	Obj(ii)=SOFAload(sourcefn);
end

%% Merging the objects
disp('Merging to a single SOFA object');
tic;
ObjFull=Obj(1);
for ii=2:length(radius)
	ObjFull=SOFAmerge(ObjFull,Obj(ii));
end
disp(['  Elapsed time: ' num2str(toc) ' s.']);
x=whos('ObjFull');
disp(['  Memory requirements: ' num2str(round(x.bytes/1024)) ' kb']);

%% save the object as a single SOFA file
warning('off','SOFA:save');
SOFAfn=fullfile(SOFAdbPath,'sofatoolbox_test',[TUBfile 'radius_' sprintf('%g_',radius) 'm.sofa']);
disp(['Saving:  ' SOFAfn]);
tic;
Obj=SOFAsave(SOFAfn, ObjFull, compression);
x=whos('ObjFull');
disp(['Saved ' num2str(round(x.bytes/1024)) ' kb in ' num2str(toc) ' s.']);

%% Plot IRs for a single direction but different radius
azi=0; ele=0;
idx=find(Obj.SourcePosition(:,1)==azi & Obj.SourcePosition(:,2)==ele);
figure('Name',mfilename);
plot(squeeze(ObjFull.Data.IR(idx,1,:))');
legend(num2str(ObjFull.SourcePosition(idx,3)))
title('IRs for the left ear with radius as parameter retrieved from a merged object');
xlabel(' index (sample taps)');
ylabel('Amplitude');
