function isis = decheveigne2023_spikepoisson(nspikes, rate)%DECHEVEIGNE2023_SPIKEPOISSON%%   Usage:%     isis=decheveigne2023_spike_poisson(nspikes, rate) - simulation of poisson process%%   Input parameters:%     nspikes : number of interspike intervals%     rate    : nominal rate (spikes/s)%%   Output parameters:%     isis : array of interspike intervals%   #StatusDoc: Unknown%   #StatusCode: Unknown%   #Verification: Unknown%   #Requirements: Unknown%   #Author: Alain de Cheveigne (2023)%   #Authors: Alejandro Osses (2023): integration in AMT 1.4% This file is licensed unter the GNU General Public License (GPL) either % version 3 of the license, or any later version as published by the Free Software % Foundation. Details of the GPLv3 can be found in the AMT directory "licences" and % at <https://www.gnu.org/licenses/gpl-3.0.html>. % You can redistribute this file and/or modify it under the terms of the GPLv3. % This file is distributed without any warranty; without even the implied warranty % of merchantability or fitness for a particular purpose. if nargin<2; error('!'); end%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% uniformly distributed random numbers, no zeroswhile 1	isis = rand(fix(nspikes),1);	if all(find(isis)) break; end;end% intervals of Poisson process are log distributedisis = -log(isis) / rate;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%if nargout==0    disp('spike_poisson: no output requested, plot ISI histogram');    spike_isih(cumsum(isis)); % expects spike times    clear spikesendend % function
%
%   Url: http://amtoolbox.org/amt-1.4.0/doc/modelstages/decheveigne2023_spikepoisson.php

function isis = decheveigne2023_spikepoisson(nspikes, rate)%DECHEVEIGNE2023_SPIKEPOISSON%%   Usage:%     isis=decheveigne2023_spike_poisson(nspikes, rate) - simulation of poisson process%%   Input parameters:%     nspikes : number of interspike intervals%     rate    : nominal rate (spikes/s)%%   Output parameters:%     isis : array of interspike intervals%   #StatusDoc: Unknown%   #StatusCode: Unknown%   #Verification: Unknown%   #Requirements: Unknown%   #Author: Alain de Cheveigne (2023)%   #Authors: Alejandro Osses (2023): integration in AMT 1.4% This file is licensed unter the GNU General Public License (GPL) either % version 3 of the license, or any later version as published by the Free Software % Foundation. Details of the GPLv3 can be found in the AMT directory "licences" and % at <https://www.gnu.org/licenses/gpl-3.0.html>. % You can redistribute this file and/or modify it under the terms of the GPLv3. % This file is distributed without any warranty; without even the implied warranty % of merchantability or fitness for a particular purpose. if nargin<2; error('!'); end%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%% uniformly distributed random numbers, no zeroswhile 1	isis = rand(fix(nspikes),1);	if all(find(isis)) break; end;end% intervals of Poisson process are log distributedisis = -log(isis) / rate;%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%if nargout==0    disp('spike_poisson: no output requested, plot ISI histogram');    spike_isih(cumsum(isis)); % expects spike times    clear spikesendend % function
