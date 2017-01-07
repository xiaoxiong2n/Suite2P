function [dreg, Valid, ds0]= blockRegisterMovieSmooth(data, ops, ds)

ops.regSmooth  = getOr(ops, {'regSmooth'}, 0);
ops.quadBlocks = getOr(ops, {'quadBlocks'}, 0);


orig_class = class(data);

% if ops.useGPU
%     data = gpuArray(single(data));
% end
[Ly, Lx, NT] = size(data);

%%
numBlocks = ops.numBlocks;
xyMask    = ops.xyMask;

xg = [1:Ly]';
xt = [];
for ib = 1:numBlocks
    xt(ib) = round(mean(ops.yBL{ib}));
end
xt = xt';

if ops.useGPU
    xt = gpuArray(single(xt));
end
    
if ops.quadBlocks    
    % within frame smoothing
    xm  = xt - mean(xt);
    xm2 = sum(xm.^2);
    for j = 1:2
        f   = squeeze(ds(:,j,:))';
        dxg = fitQuad(xt, f, xg);
        dxg = repmat(dxg,1,1,Lx);
        dxg = permute(dxg,[1 3 2]);
        if j == 1
            dy = dxg;
        else
            dx = dxg;
        end
    end
    clear dxg xt;
else
    dx = xyMask(:,1:numBlocks) * squeeze(ds(:,2,:))';
    dy = xyMask(:,1:numBlocks) * squeeze(ds(:,1,:))';
    
end
ds0 = gather_try([dy(:,:) dx(:,:)]);

dx = round(dx);
dy = round(dy);

idy = repmat([1:Ly]', 1, Lx);
idx = repmat([1:Lx],  Ly, 1) ;

dreg = zeros(size(data), orig_class);
Valid = true(Ly, Lx);
for i = 1:NT
    Im = data(:,:,i);    
    
    DX = repmat(dx(:,i),1,Lx) + idx;
    DY = repmat(dy(:,i),1,Lx) + idy;
    
    
    xyInvalid = DX<1 | DX>Lx | DY<1 | DY>Ly;
    Valid(xyInvalid) = false;
    
    DX(xyInvalid) = 0;
    DY(xyInvalid) = 0;
    
%     DX = mod(DX, Lx);
%     DY = mod(DY-1, Ly) + 1;
%     
    ind = DY + (DX-1) * Ly;
    Im = Im(ind);
    dreg(:,:,i) = Im;
    
end

