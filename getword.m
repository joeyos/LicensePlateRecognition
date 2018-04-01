function[word,result]=getword(d)
word=[];
flag=0;
y1=8;
y2=0.5;
while flag==0
    [m,n]=size(d);
    wide=0;
    while sum(d(:,wide+1))~=0 && wide<=n-2
        wide=wide+1;
    end
    temp=qiege(imcrop(d,[1 1 wide m]));%用于返回图像的一个裁剪区域
    [m1,n1]=size(temp);
    if wide<y1 && n1/m1>y2
        d(:,[1:wide])=0;
        if sum(sum(d))~=0
            d=qiege(d);%切割出最小范围
        else word=[];flag=1;
        end
    else
        word=qiege(imcrop(d,[1 1 wide m]));
        d(:,[1:wide])=0;
        if sum(sum(d))~=0;
            d=qiege(d);
            flag=1;
        else d=[];
        end
    end
end
result=d;