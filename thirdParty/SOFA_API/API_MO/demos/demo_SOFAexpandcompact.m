% This demo shows how to use SOFAexpand and SOFAcompact
% It requires the TU-Berlin KEMAR HRTFs for different radii in the SOFA
% directory. These files can be generated by demo_TUBerlin2SOFA

% #Author: Piotr Majdak
% #Author: Michael Mihocic: header documentation updated (28.10.2021)
% 
% SOFA API - demo script
% Copyright (C) 2012-2021 Acoustics Research Institute - Austrian Academy of Sciences
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

%% Load the objects 
clear Obj;
for ii=1:length(radius)
	sourcefn=fullfile(SOFAdbPath, 'database', 'tu-berlin', [TUBfile num2str(radius(ii)) 'm.sofa']);
	disp(['Loading: ' sourcefn]);
	Obj(ii)=SOFAload(sourcefn);
end

%% Expanding the objects
x=whos('Obj');
disp('Expanding the objects');
tic;
clear Expanded
for ii=1:length(radius)
	Expanded(ii)=SOFAexpand(Obj(ii));
end
disp(['  Elapsed time: ' num2str(toc) ' s.']);
y=whos('Expanded');
disp(['  Expanded object array is now larger by ' num2str(round((y.bytes-x.bytes)/1024)) ' kb']);

%% Compress the object 
disp('Compressing the objects');
tic;
clear Compacted
for ii=1:length(radius)
	Compacted(ii)=SOFAcompact(Expanded(ii));
end
disp(['  Elapsed time: ' num2str(toc) ' s.']);
y=whos('Compacted');
disp(['  Compacted object array is now as small as the original one. Difference: ' num2str(round((x.bytes-y.bytes)/1024)) ' kb']);
