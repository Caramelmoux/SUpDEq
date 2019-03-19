function [g,asan,info] = filterbankwin(g,a,varargin);
%FILTERBANKWIN  Compute set of filter bank windows from text or cell array
%   Usage: [g,info] = filterbankwin(g,a,L);
%
%   [g,info]=FILTERBANKWIN(g,a,L) computes a window that fits well with
%   time shift a and transform length L. The window itself is as a cell
%   array containing additional parameters.
%
%   The window can be specified directly as a cell array of vectors of
%   numerical values. In this case, FILTERBANKWIN only checks assumptions
%   about transform sizes etc.
%
%   [g,info]=FILTERBANKWIN(g,a) does the same, but the windows must be FIR
%   windows, as the transform length is unspecified.
%
%   FILTERBANKWIN(...,'normal') computes a window for regular
%   filterbanks, while FILTERBANKWIN(...,'real') does the same for the
%   positive-frequency only filterbanks.
%
%   The window can also be specified as cell array. The possibilities are:
%
%     {'dual',...}
%         Canonical dual window of whatever follows. See the examples below.
%
%     {'realdual',...}
%         Canonical dual window for a positive-frequency filterbank
%         of whatever follows. See the examples below.
%
%     {'tight',...}
%         Canonical tight window of whatever follows. See the examples below.
%
%     {'realtight',...} 
%         Canonical tight window for a real-valued for a positive
%         frequency filterbank of whatever follows.
%
%   The structure info provides some information about the computed
%   window:
%
%     info.M
%        Number of windows (equal to the number of channels)
%
%     info.longestfilter
%        Length of the longest filter
%
%     info.gauss
%        True if the windows are Gaussian.
%
%     info.tfr
%        Time/frequency support ratios of the window. Set whenever it makes sense.
%
%     info.isfir
%        Input is an FIR window
%
%     info.isdual
%        Output is the dual window of the auxiliary window.
%
%     info.istight
%        Output is known to be a tight window.
%
%     info.auxinfo
%        Info about auxiliary window.
%   
%     info.gl
%        Length of windows.
%
%     info.isfac
%        True if the frame generated by the window has a fast factorization.
%
%   See also: filterbank, filterbankdual, filterbankrealdual
%
%   Url: http://ltfat.github.io/doc/filterbank/filterbankwin.html

% Copyright (C) 2005-2016 Peter L. Soendergaard <peter@sonderport.dk>.
% This file is part of LTFAT version 2.2.0
%
% This program is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% This program is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with this program.  If not, see <http://www.gnu.org/licenses/>.

% TO DO: Why is there a realtype flag?
% Assert correct input.
if nargin<2
  error('%s: Too few input parameters.',upper(mfilename));
end;

if ~iscell(g)
  error('%s: Window(s) g must be a cell array.',upper(mfilename));
end;

if isempty(g) || any(cellfun(@isempty,g))
  error('%s: Window(s) g must not be empty.',upper(mfilename));
end;

definput.keyvals.L=[];
definput.flags.realtype={'normal','real'};
[flags,kv,L]=ltfatarghelper({'L'},definput,varargin);

if ischar(g{1})
    winname=lower(g{1});
    switch(winname)
      case {'dual'}
        optArgs = g(3:end);
        [g,~,info.auxinfo] = filterbankwin(g{2},a,L);
        g = filterbankdual(g,a,L,optArgs{:});
        info.isdual=1;
        
      case {'realdual'}
        optArgs = g(3:end);
        [g,~,info.auxinfo] = filterbankwin(g{2},a,L);
        g = filterbankrealdual(g,a,L,optArgs{:});
        info.isdual=1;
        
      case {'tight'}
        [g,~,info.auxinfo] = filterbankwin(g{2},a,L);    
        g = filterbanktight(g,a,L);
        info.istight=1;
        
      case {'realtight'}
        [g,~,info.auxinfo] = filterbankwin(g{2},a,L);    
        g = filterbankrealtight(g,a,L);        
        info.istight=1;
        
      otherwise
        error('%s: Unsupported window type %s.',winname,upper(mfilename));
    end;
end;

do_info = nargout>2;

info.M=numel(g);
info.gl=zeros(info.M,1);
info.offset=zeros(info.M,1);
info.ispainless=1;
info.isfractional=0;
info.isuniform=0;
info.isfir=1;

[asan,info]=comp_filterbank_a(a,info.M,info);

for m=1:info.M
    [g{m},info_win] = comp_fourierwindow(g{m},L,upper(mfilename));    
    if do_info
        if isfield(g{m},'H') 
            % Here we only want to find out the frequency support 
            if isa(g{m}.H,'function_handle')
                if isempty(L)
                    error('L:undefined',...
                           ['%s: L is necessary for determining support ',...
                           'of g.H'],upper(mfilename));
                end
                tmpH=g{m}.H(L);
            elseif isnumeric(g{m}.H)
                tmpH=g{m}.H;
                if isempty(L) || L == g{m}.L;
                    % There has to be g{m}.L already present
                    L = g{m}.L;
                else
                    % In case L ~= g{m}.L we cannot be sure whether g is
                    % still band-limited 
                    info.ispainless=0;
                end
            end;
        
            % Check the painless condition
            if numel(tmpH) > L/asan(m,1)*asan(m,2);
                info.ispainless=0; 
            end
        else
            % No subsampling means painless case for any filter
            if ~(info.isuniform && asan(m,1) == 1)
                info.ispainless=0;
            end
            info.gl(m)=numel(g{m}.h);
            info.offset(m)=g{m}.offset;
        end;
    end
    
    if info_win.isfir && asan(m,2) ~=1
        % FIR filter cannot have a fractional subsampling
        if rem(asan(m,1)/asan(m,2),1)==0
            % ... but this is still an integer subsampling
            asan = [asan(m,1)/asan(m,2),1];
            info.a(m,:) = asan;
        else
            error(['%s: Fractional subsampling cannot be used with FIR '...
                   'filters.'],upper(mfilename));
        end
    end
    
    % info.isfir==1 only if all filters are FIR
    if isfield(info_win,'isfir')
       if ~info_win.isfir && info.isfir
          info.isfir = 0;
       end
    end
end;

info.isfac=info.isuniform || info.ispainless;


if info.isfractional && info.isuniform
    error('%s: The uniform algorithms cannot handle fractional downsampling.', ...
          upper(mfilename));
end;

if info.isfir
   info.longestfilter=max(info.gl);

   % Does not evaluate as true if L is empty
   if L<info.longestfilter
     error('%s: One of the windows is longer than the transform length= %i.',upper(mfilename),info.longestfilter);
   end;
end



