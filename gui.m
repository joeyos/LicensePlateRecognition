function varargout = gui(varargin)
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @gui_OpeningFcn, ...
                   'gui_OutputFcn',  @gui_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end
if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
%结束初始化
function gui_OpeningFcn(hObject, eventdata, handles, varargin)
handles.output = hObject;
guidata(hObject, handles);
function varargout = gui_OutputFcn(hObject, eventdata, handles) 
varargout{1} = handles.output;

% ======================输入图像===============================
function pushbutton1_Callback(hObject, eventdata, handles)
[filename pathname]=uigetfile({'*.jpg';'*.bmp'}, 'File Selector');
I=imread([pathname '\' filename]);
handles.I=I;
guidata(hObject, handles);
axes(handles.axes1);
imshow(I);title('原图');

% ======================图像处理===============================
function pushbutton2_Callback(hObject, eventdata, handles)
I=handles.I;
I1=rgb2gray(I);
I2=edge(I1,'roberts',0.18,'both');
axes(handles.axes2);
imshow(I1);title('灰度图');
axes(handles.axes3);
imshow(I2);title('边缘检测');
se=[1;1;1];
I3=imerode(I2,se);%腐蚀操作
se=strel('rectangle',[25,25]);
I4=imclose(I3,se);%图像聚类，填充图像
I5=bwareaopen(I4,2000);%去除聚团灰度值小于2000的部分
[y,x,z]=size(I5);%返回15各维的尺寸，存储在x,y,z中
myI=double(I5);
tic      %tic计时开始，toc结束
Blue_y=zeros(y,1);%产生一个y*1的零针
for i=1:y
    for j=1:x
        if(myI(i,j,1)==1)%如果myI图像坐标为（i，j）点值为1，即背景颜色为蓝色，blue加一
            Blue_y(i,1)=Blue_y(i,1)+1;%蓝色像素点统计
        end
    end
end
[temp MaxY]=max(Blue_y);
%Y方向车牌区域确定
%temp为向量yellow_y的元素中的最大值，MaxY为该值得索引
PY1=MaxY;
while((Blue_y(PY1,1)>=5)&&(PY1>1))
    PY1=PY1-1;
end
PY2=MaxY;
while((Blue_y(PY2,1)>=5)&&(PY2<y))
    PY2=PY2+1;
end
IY=I(PY1:PY2,:,:);
%X方向车牌区域确定
Blue_x=zeros(1,x);%进一步确认x方向的车牌区域
for j=1:x
    for i=PY1:PY2
        if(myI(i,j,1)==1)
            Blue_x(1,j)=Blue_x(1,j)+1;
        end
    end
end
PX1=1;
while((Blue_x(1,PX1)<3)&&(PX1<x))
    PX1=PX1+1;
end
PX2=x;
while((Blue_x(1,PX2)<3)&&(PX2>PX1))
    PX2=PX2-1;
end
PX1=PX1-1;%对车牌区域的矫正
PX2=PX2+1;
dw=I(PY1:PY2-8,PX1:PX2,:);
t=toc;
axes(handles.axes4);imshow(dw),title('定位车牌');
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
imwrite(dw,'dw.jpg');%将彩色车牌写入dw文件中
a=imread('dw.jpg');%读取车牌
b=rgb2gray(a);%将车牌图像转换为灰度图
imwrite(b,'灰度车牌.jpg');%将灰度图写入文件
g_max=double(max(max(b)));
g_min=double(min(min(b)));
T=round(g_max-(g_max-g_min)/3);%T为二值化的阈值
[m,n]=size(b);
d=(double(b)>=T);%d:二值图像
imwrite(d,'二值化.jpg');
%均值滤波前
%滤波
h=fspecial('average',3);
%建立预定义的滤波算子，average为均值滤波，模板尺寸为3*3
d=im2bw(round(filter2(h,d)));%使用指定的滤波器h对h进行d即均值滤波
imwrite(d,'均值滤波.jpg');
%某些图像进行操作
%膨胀或腐蚀
se=eye(2);%单位矩阵
[m,n]=size(d);%返回信息矩阵
if bwarea(d)/m/n>=0.365%计算二值图像中对象的总面积与整个面积的比是否大于0.365
    d=imerode(d,se);%如果大于0.365则进行腐蚀
elseif bwarea(d)/m/n<=0.235%计算二值图像中对象的总面积与整个面积的比值是否小于0.235
    d=imdilate(d,se);%%如果小于则实现膨胀操作
end
imwrite(d,'膨胀.jpg');
%寻找连续有文字的块，若长度大于某阈值，则认为该块有两个字符组成，需要分割
d=qiege(d);
[m,n]=size(d);
k1=1;
k2=1;
s=sum(d);
j=1;
while j~=n
    while s(j)==0
        j=j+1;
    end
    k1=j;
    while s(j)~=0 && j<=n-1
        j=j+1;
    end
    k2=j-1;
    if k2-k1>=round(n/6.5)
        [val,num]=min(sum(d(:,[k1+5:k2-5])));
        d(:,k1+num+5)=0;%分割
    end
end
%再切割
d=qiege(d);
%切割出7个字符
y1=10;
y2=0.25;
flag=0;
word1=[];
while flag==0
    [m,n]=size(d);
    left=1;
    wide=0;
    while sum(d(:,wide+1))~=0
        wide=wide+1;
    end
    if wide<y1 %认为是左干扰 
        d(:,[1:wide])=0;
        d=qiege(d);
    else
        temp=qiege(imcrop(d,[1 1 wide m]));
        [m,n]=size(temp);
        all=sum(sum(temp));
        two_thirds=sum(sum(temp([round(m/3):2*round(m/3)],:)));
        if two_thirds/all>y2
            flag=1;word1=temp;%word1
        end
        d(:,[1:wide])=0;d=qiege(d);
    end
end
%分割出第二至七个字符
[word2,d]=getword(d);
[word3,d]=getword(d);
[word4,d]=getword(d);
[word5,d]=getword(d);
[word6,d]=getword(d);
[word7,d]=getword(d);
[m,n]=size(word1);
%商用系统程序中归一化大小为40*20
word1=imresize(word1,[40 20]);
word2=imresize(word2,[40 20]);
word3=imresize(word3,[40 20]);
word4=imresize(word4,[40 20]);
word5=imresize(word5,[40 20]);
word6=imresize(word6,[40 20]);
word7=imresize(word7,[40 20]);
axes(handles.axes5);imshow(word1),title('1');
axes(handles.axes6);imshow(word2),title('2');
axes(handles.axes7);imshow(word3),title('3');
axes(handles.axes8);imshow(word4),title('4');
axes(handles.axes9);imshow(word5),title('5');
axes(handles.axes10);imshow(word6),title('6');
axes(handles.axes11);imshow(word7),title('7');
imwrite(word1,'1.jpg');
imwrite(word2,'2.jpg');
imwrite(word3,'3.jpg');
imwrite(word4,'4.jpg');
imwrite(word5,'5.jpg');
imwrite(word6,'6.jpg');
imwrite(word7,'7.jpg');
liccode=char(['0':'9' 'A':'Z' '辽粤豫鄂鲁陕京津']);%京津沪渝冀豫云辽黑湘皖鲁新苏浙赣鄂桂甘晋蒙陕吉闽贵粤青藏川宁琼
SubBw2=zeros(40,20);
l=1;
for I=1:7;
    ii=int2str(I);
    t=imread([ii,'.jpg']);
    SegBw2=imresize(t,[40 20],'nearest');
    SegBw2=double(SegBw2)>20;
    if l==1 %第一位汉字识别
        kmin=37;
        kmax=43;
    elseif l==2 %第二位字母识别
        kmin=11;
        kmax=36;
    else l>=3   %第三位后字母或数字识别
        kmin=1;
        kmax=36;
    end
    for k2=kmin:kmax
        fname=strcat('字符模板\',liccode(k2),'.jpg');
        SamBw2=imread(fname);
        SamBw2=double(SamBw2)>1;
        for i=1:40
            for j=1:20
                SubBw2(i,j)=SegBw2(i,j)-SamBw2(i,j);
            end
        end
        %相当于两幅图相减得第三幅图
        Dmax=0;
        for k1=1:40;
            for l1=1:20
                if(SubBw2(k1,l1)>0 | SubBw2(k1,l1)<0)
                    Dmax=Dmax+1;
                end
            end
        end
        Error(k2)=Dmax;
    end
    Error1=Error(kmin:kmax);
    MinError=min(Error1);
    findc=find(Error1==MinError);
    Code(l*2-1)=liccode(findc(1)+kmin-1);
    Code(l*2)=' ';
    l=l+1;
end
axes(handles.axes12);imshow(dw),title(['车牌号码：',Code],'Color','b');
axes(handles.axes13);imhist(I1);title('灰度化直方图');

% ==========================退出系统============================
function pushbutton3_Callback(hObject, eventdata, handles)
close(gcf);



