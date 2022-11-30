function D = driving_function_mono_wfs_vss(x0,xv,srcv,Dv,f,conf)
%DRIVING_FUNCTION_MONO_WFS_VSS driving signal for a given set of virtual
%secondary sources and their driving signals
%
%   Usage: D = driving_function_mono_wfs_vss(x0,xv,srcv,Dv,f,conf)
%
%   Input parameters:
%       x0          - position, direction, and weights of the real secondary
%                     sources / m [nx7]
%       xv          - position, direction, and weights of the virtual secondary
%                     sources / m [mx7]
%       srcv        - type of virtual secondary sources [mx7]
%                         'pw' - plane wave (xv(:,1:3) defines the direction of 
%                                the plane waves in this case)
%                         'fs' - focused source (xv(:,1:6) defines the position
%                                and orientation of the focused sources in this 
%                                case)
%       Dv          - driving functions of virtual secondary sources [mx1]
%       f           - frequency / Hz
%       conf        - optional configuration struct (see SFS_config)
%
%   Output parameters:
%       D           - driving function [nx1]
%
%   See also: driving_function_mono_wfs, driving_function_mono_wfs_fs
%
%   References:
%       Spors and Ahrens (2010) - "Local Sound Field Synthesis by Virtual
%       Secondary Sources", in 40th Conference of the Audio Engineering Society,
%       Paper 6-3, http://www.aes.org/e-lib/browse.cfm?elib=15561

%*****************************************************************************
% The MIT License (MIT)                                                      *
%                                                                            *
% Copyright (c) 2010-2019 SFS Toolbox Developers                             *
%                                                                            *
% Permission is hereby granted,  free of charge,  to any person  obtaining a *
% copy of this software and associated documentation files (the "Software"), *
% to deal in the Software without  restriction, including without limitation *
% the rights  to use, copy, modify, merge,  publish, distribute, sublicense, *
% and/or  sell copies of  the Software,  and to permit  persons to whom  the *
% Software is furnished to do so, subject to the following conditions:       *
%                                                                            *
% The above copyright notice and this permission notice shall be included in *
% all copies or substantial portions of the Software.                        *
%                                                                            *
% THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR *
% IMPLIED, INCLUDING BUT  NOT LIMITED TO THE  WARRANTIES OF MERCHANTABILITY, *
% FITNESS  FOR A PARTICULAR  PURPOSE AND  NONINFRINGEMENT. IN NO EVENT SHALL *
% THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER *
% LIABILITY, WHETHER  IN AN  ACTION OF CONTRACT, TORT  OR OTHERWISE, ARISING *
% FROM,  OUT OF  OR IN  CONNECTION  WITH THE  SOFTWARE OR  THE USE  OR OTHER *
% DEALINGS IN THE SOFTWARE.                                                  *
%                                                                            *
% The SFS Toolbox  allows to simulate and  investigate sound field synthesis *
% methods like wave field synthesis or higher order ambisonics.              *
%                                                                            *
% https://sfs.readthedocs.io                            sfstoolbox@gmail.com *
%*****************************************************************************

%% ===== Checking of input  parameters ==================================
nargmin = 6;
nargmax = 6;
narginchk(nargmin,nargmax);
isargvector(Dv);
isargpositivescalar(f);
isargchar(srcv);
isargsecondarysource(x0,xv);
isargstruct(conf);


%% ===== Configuration ==================================================
dimension = conf.dimension;


%% ===== Computation ====================================================
% Secondary source selection and driving function to synthesise a single virtual
% secondary source
switch srcv
case 'fs'
    ssd_select = @(X0,XS) secondary_source_selection(X0,XS(1:6),'fs');
    driv = @(X0,XS) driving_function_mono_wfs_fs(X0(:,1:3),X0(:,4:6),XS,f,conf);
    
    if strcmp('2.5D',dimension) || strcmp('3D',dimension)
        % === Focussed Point Sink ===
        conf.driving_functions = 'default';
    elseif strcmp('2D',dimension)
        % === Focussed Line Sink ===
        % We have to use the driving function setting directly, because in 
        % opposite to the case of a non-focused source where 'ps' and 'ls' are
        % available as source types, for a focused source only 'fs' is 
        % available. Have a look at driving_function_mono_wfs_fs() for details
        % on the implemented focused source types.
        conf.driving_functions = 'line_sink';
    else
        error('%s: %s is not a known source type.',upper(mfilename),dimension);
    end    
case 'pw'
    ssd_select = @(X0,XS) secondary_source_selection(X0,XS(1:3),'pw');
    driv = @(X0,XS) driving_function_mono_wfs_pw(X0(:,1:3),X0(:,4:6),XS,f,conf);
end

% Get driving signals
Nv = size(xv,1);
N0 = size(x0,1);
Dmatrix = zeros(N0,Nv);

% it's ok to have zero secondary sources selected for pwd
warning('off','SFS:x0'); 
for idx=1:Nv
    [x0s, xdx] = ssd_select(x0,xv(idx,:));
    if (~isempty(x0s))
        % Virtual secondary source position
        xs = repmat(xv(idx,1:3),[size(x0s,1) 1]);
        % Optional tapering
        wtap = tapering_window(x0s,conf);
        Dmatrix(xdx,idx) = driv(x0s,xs) .* wtap;
    end
end
warning('on','SFS:x0');

D = Dmatrix*(Dv(:).*xv(:,7));
