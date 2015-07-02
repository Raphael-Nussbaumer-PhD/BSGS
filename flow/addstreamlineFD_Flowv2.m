function [x,y,tof] = addstreamlineFD_Flowv2(xo,yo,NX,NY,DX,DY,ux,uy,P0,P1)

% [x,y,tof] = addstreamline(xo,yo,NX,NY,DX,DY,ux,uy,P0,P1);

k = 1;
tof = 0;
epsilon = 1.e-6;
% megalon = 1.e6;
erreur = 0;

% points de depart de la ligne
x(k) = xo;
y(k) = yo;
%numero de la maille ou on entre
xmaille(k) = 1;
ymaille(k) = ceil(yo/DY);
% cote de la maille par ou on entre
% cote = 1 pour gauche
% cote = 2 pour bas
% cote = 3 pour haut
% cote = 4 pour droite
% cote = 5 pour, on est deja dedans !
cote(k) = 1;

if P0 > P1
	limite = (NX-1)*DX*(1-epsilon);
else
	limite = DX*(1+epsilon);
end

for iloop = 1:NX*NY;
	
	% dtex = 0;
	% dtey = 0;
	% dte = 0;
	
	% coordonnees de la maille ou on entre
	if cote(k) == 1
		i = ymaille(k);
		j = xmaille(k)+1;
	elseif cote(k) == 2
		i = ymaille(k)+1;
		j = xmaille(k);
	elseif cote(k) == 3
		i = ymaille(k)-1;
		j = xmaille(k);
	elseif cote(k) == 4
		i = ymaille(k);
		j = xmaille(k)-1;
	elseif cote(k) == 5
		i = ymaille(k);
		j = xmaille(k);
	end
	
	%origine de la maille
	xo = (j-1)*DX;
	yo = (i-1)*DY;
	
	% vitesse au point origine
	vxo = ux(i,j-1);
	if i > 1
		vyo = uy(i-1,j);
	else
		vyo = 0;
	end
	
	% position d'entree
	xi = x(k);
	yi = y(k);
	
	% gradients de vitesse dans la maille a traverser
	% suivant l'axe x
	mx = (ux(i,j)-vxo)/DX;
	
	% Calcul de la position de sortie suivant x
	%-----------------------------------
	
	if cote(k) ~= 4
		xe = j*DX;
	else
		xe = (j-1)*DX;
	end
	
	% Calcul des vitesses sur x aux points d'entr�e et de sortie
	vxout = vxo+mx*(xe-xo);
	vxin = vxo+mx*(xi-xo);
	
	% temps de traversee suivant x
	%-----------------------------------
	if (abs(mx) < epsilon) || (abs(vxin) < epsilon) || (abs(vxout) < epsilon)
		% gradient de vitesse nul ou vitesses nulles
		dtex = 2*(xe-xi)/(vxin+vxout);
	elseif vxin*vxout > 0
		% vitesses meme signe - no flow divide
		%disp('vitesses x meme signe')
		dtex = (1/mx)*log(vxout/vxin);
	else
		% vitesses signes opposes
		% disp('signes vitesses x opposees');
		%         dtex = megalon;
		dtex = (1/mx)*log(-vxout/vxin);
	end
	
	% Calcul de la position de sortie suivant y
	%-------------------------------------------
	if i < NY
		vhaut = uy(i,j);
	else
		vhaut = 0;
	end
	my = (vhaut-vyo)/DY;
	
	% points de sortie
	if vyo*vhaut >= 0
		% soit vyo et vhaut negatif soit vyo et vhaut positif
		if vyo >= 0
			ye = i*DY;
		else
			ye = (i-1)*DY;
		end
	else
		% soit vyo negatif et vhaut positif soit vyo positif et vhaut
		% negatif
		if vyo < 0
			% premier cas
			b = vyo;
			a = (vhaut-vyo)/DY;
			dy = -b/a;
			ytest = y(k)-yo;
			if ytest > dy
				ye = i*DY;
			else
				ye = (i-1)*DY;
			end
		else
			% second cas
			b = vyo;
			a = (vhaut-vyo)/DY;
			dy = -b/a;
			ytest = y(k)-yo;
			if ytest > dy
				ye = i*DY;
			else
				ye = (i-1)*DY;
			end
			%disp('pas de sortie ye');
			%dtey = megalon;
		end
	end
	% Calcul des vitesses sur x aux points d'entr�e et de sortie
	vyin = vyo+my*(yi-yo);
	vyout = vyo+my*(ye-yo);
	
	% Calcul du temps de traversee en y
	%-----------------------------------
	if (abs(my) < epsilon) || (abs(vyin) < epsilon) || (abs(vyout) < epsilon)
		% gradient de vitesse nul ou vitesses nulles
		dtey = (ye-yi)/vyo;
	elseif vyin*vyout > 0
		% vitesses meme signe - no flow divide
		%disp('vitesses x meme signe')
		dtey = (1/my)*log(vyout/vyin);
	else
		% vitesses signes opposes
		%disp('signes vitesses y opposees');
		%         dtex = megalon;
		dtey = (1/my)*log(-vyout/vyin);
	end
	
	temps = [dtex dtey];

	temps_pos = temps(temps > 0);
	temps = temps_pos(temps_pos > epsilon);
	dte = min(temps);
	if min(size(temps)) == 0
		dte = 0;
	end
	tof = tof+dte;
	
	k = k+1;
	
	% point de sortie
	if abs(mx) > epsilon
		% vitesse non uniforme
		x(k) = xo+(exp(mx*dte)*vxin-vxo)/mx;
	else
		% vitesse uniforme
		x(k) = xo+dte*vxo;
	end
	if abs(my) > epsilon
		% vitesse non uniforme
		y(k) = yo+(exp(my*dte)*vyin-vyo)/my;
	else
		%vitesse uniforme
		y(k) = yo+dte*vyo;
	end
	
	
	xmaille(k) = j;
	ymaille(k) = i;
	
	% bug sortie maille
	bug = 0;
	testbug = floor(y(k)/DY);
	if (testbug ~= i-1)
		bug = 1;
	end
	
	%plot(x(k),y(k),'r.','MarkerSize',20)
	%prochain cote entrant
	if abs(x(k)-xmaille(k)*DX) < epsilon*DX
		%disp('va entrer par gauche')
		cote(k) = 1;
	elseif abs(y(k)-ymaille(k)*DY) < epsilon*DY
		%disp('va entrer par bas')
		cote(k) = 2;
	elseif abs(y(k)-(ymaille(k)-1)*DY) < epsilon*DY
		%disp('va entrer par haut')
		cote(k) = 3;
	elseif abs(x(k)-(xmaille(k)-1)*DX) < epsilon*DX
		%disp('va entrer par droite')
		cote(k) = 4;
	else
		cote(k) = 5;
		%disp('probleme: cote 5')
		%k
		% erreur = 1;
		%break;
	end
	
	
	%critere d'arret
	if P0 > P1
		if x(k) > limite
			break;
		end
	else
		if x(k) < limite
			break;
		end
	end
	%pause
	
end

clear xmaille ymaille cote
if erreur == 1
	x = [];
	y = [];
	tof = 0;
end
if bug == 1
	x = [];
	y = [];
	tof = 0;
end
return;
