! Subroutines for mapping CLM 1D output to 3D (elevation class, lat,
! lon) and interpolating elevation class output to a high-resolution ice
! sheet.
! Written by Raymond Sellevold, for questions e-mail:
! R.Sellevold-1@tudelft.nl.
! These subroutines have been tested for use with python/numpy. Compile
! fortran scipt by typing (where you can replace <module name> with what
! you want to call it):
! f2py -c -m <module name> fortran_funcs.F90
! and call in python with:
! import <module name>

      SUBROUTINE pft2latlo(nt,nk,ltype,jxy,ixy,varpft,col,ou)
      implicit none
      integer :: t, k
      integer :: mylatidx, mylonidx, lev
      integer, intent(in) :: nt, nk, col
      integer, intent(in) :: ltype(nk), jxy(nk), ixy(nk)
      real, intent(in) :: varpft(nk,nt)
      real, intent(inout) :: ou(:,:,:,:)

      ! nt = number of time samples
      ! nk = length of CLM 1d array
      ! ltype = (pftunit / colunit)
      ! jxy = (pfts1d_jxy / cols1d_jxy)
      ! ixy = (pfts1d_ixy / cols1d_ixy)
      ! varpft = variable read from CLM output
      ! col = landunit number to downscale onto
      ! ou = output in form of (lon, lat, elevationclass, time)

      mylatidx = 0
      mylonidx = 0
      lev = 0

      do t=1,nt
       do k=1,nk
        if (ltype(k) == col) then
         if ((mylatidx.eq.jxy(k)).and.(mylonidx.eq.ixy(k))) then
          lev = lev + 1
         else
          mylatidx = jxy(k)
          mylonidx = ixy(k)
         end if
         ou(ixy(k),jxy(k),lev,t) = varpft(k,t)
        end if
       enddo
      enddo

      return
      END SUBROUTINE


      SUBROUTINE BILIN_INTERP(kp,cism_lat,cism_lon,clm_lonx,clm_lat,v,a)
      implicit none
      integer, parameter :: cism_ny=704, cism_nx=416
      integer, parameter :: clm_ny=192, clm_nx=288
      integer :: mec, y, x
      integer :: clm_point_x1, clm_point_x2
      integer :: clm_point_y1, clm_point_y2
      real :: cism_lon_x
      real :: cism_lat_y
      real :: clm_lon_x1, clm_lon_x2, clm_lat_y1, clm_lat_y2
      real :: dist, distA, distB, distC, distD, dists(4)
      real :: valA, valB, valC, valD, vars(4)

      integer, intent(in) :: kp
      real, intent(in) :: cism_lat(cism_ny,cism_nx)
      real, intent(in) :: cism_lon(cism_ny,cism_nx)
      real, intent(in) :: clm_lonx(clm_nx)
      real, intent(in) :: clm_lat(clm_ny)
      real, intent(in) :: v(kp,clm_ny,clm_nx)
      real, intent(out) :: a(kp,cism_ny,cism_nx)

!     Subroutine to calculate bilinear interpolants, assuming gridcell
!     looks like

!     CLM(x1,y2)---------------CLM(x2,y2)
!          |                         |
!          |                         |
!          |       CISM(x,y)         |
!          |                         |
!          |                         |
!     CLM(x1,y1)---------------CLM(x2,y1)

      ! kp = number of levels to do bilinear interpolations on
      ! cism_lat = array of latitudes in CISM (in deg. W)
      ! cism_lon = array of longitudes in CISM (in deg. W)
      ! clm_lonx = array of longitudes in CLM (-180,180)
      ! clm_lat = array of latitudes in CLM (-90,90)
      ! v = array containing values to be interpolated
      ! a = high(er) resolution array interpolated onto

      do mec=1,kp
       do x=1,cism_nx
        do y=1,cism_ny
         ! First find the lats and lons of the CISM point
         cism_lon_x = cism_lon(y,x)
         cism_lat_y = cism_lat(y,x)

         ! Find the indexes of the closest CLM longitude and latitude
         clm_point_x1 = minloc(abs(clm_lonx-cism_lon_x),1)
         clm_point_y1 = minloc(abs(clm_lat-cism_lat_y),1)

         ! Use this information to locate x1 and y1
         if (clm_lonx(clm_point_x1) > cism_lon_x) then
          clm_point_x1 = clm_point_x1 - 1
         endif
         if (clm_lat(clm_point_y1) > cism_lat_y) then
          clm_point_y1 = clm_point_y1 -1
         endif

         ! Find x2 and y2
         clm_point_x2 = clm_point_x1 + 1
         clm_point_y2 = clm_point_y1 + 1

         ! Assign longitudes and latitudes to x1,y1,x2,y2
         clm_lon_x1 = clm_lonx(clm_point_x1)
         clm_lon_x2 = clm_lonx(clm_point_x2)
         clm_lat_y1 = clm_lat(clm_point_y1)
         clm_lat_y2 = clm_lat(clm_point_y2)

         ! Calculate the distances from CISM(x,y) to each CLM point
         dist = ((clm_lon_x2-clm_lon_x1)*(clm_lat_y2-clm_lat_y1))
         distA = ((clm_lon_x2-cism_lon_x)*(clm_lat_y2-cism_lat_y))
         distA = distA / dist
         distB = ((cism_lon_x-clm_lon_x1)*(clm_lat_y2-cism_lat_y))
         distB = distB / dist
         distC = ((clm_lon_x2-cism_lon_x)*(cism_lat_y-clm_lat_y1))
         distC = distC / dist
         distD = ((cism_lon_x-clm_lon_x1)*(cism_lat_y-clm_lat_y1))
         distD = distD / dist

         ! Find the corresponding CLM values
         valA = v(mec,clm_point_y1,clm_point_x1)
         valB = v(mec,clm_point_y1,clm_point_x2)
         valC = v(mec,clm_point_y2,clm_point_x1)
         valD = v(mec,clm_point_y2,clm_point_x2)

         ! Multiply with the distances
         valA = valA * distA
         valB = valB * distB
         valC = valC * distC
         valD = valD * distD

         ! Mask not-a-number values and collect the values in an array
         if (valA>1E+30) then
          valA = -9999.0
          distA = -9999.0
         endif
         if (valB > 1E+30) then
          valB = -9999.0
          distB = -9999.0
         endif
         if (valC > 1E+30) then
          valC = -9999.0
          distC = -9999.0
         endif
         if (valD > 1E+30) then
          valD = -9999.0
          distD = -9999.0
         endif
         vars = (/ valA, valB, valC, valD /)
         vars = pack(vars, vars /= -9999.0)
         dists = (/ distA, distB, distC, distD /)
         dists = pack(dists, dists /= -9999.0)

         a(mec,y,x) = sum(vars) / sum(dists)
        enddo
       enddo
      enddo

      return
      END SUBROUTINE


      SUBROUTINE VERT_INTERP(points,topo,values,valout)
      implicit none
      integer, parameter :: ny=704, nx=416, nk=10
      integer :: x, y
      integer :: minp, upper, lower
      real :: dist_upper, dist_lower
      real :: val_upper, val_lower
      real, intent(in) :: points(ny,nx)
      real, intent(in) :: topo(nk,ny,nx), values(nk,ny,nx)
      real, intent(out) :: valout(ny,nx)

      ! points = topography to interplate to
      ! topo = topography of each elevation class
      ! values = values at each elevation class
      ! valout = values to return

      do x=1,nx
       do y=1,ny
        ! Find the lower limit
        minp = minloc(abs(topo(:,y,x)-points(y,x)),1)

        ! Decide if this point is the upper or lower limit of
        ! interpolation
        if (topo(minp,y,x) > points(y,x)) then
         upper = minp
         lower = minp - 1
        else
         upper = minp + 1
         lower = minp
        endif

        ! Check that the upper limit is higher than lower limit
        if (topo(upper,y,x) > topo(lower,y,x)) then
         dist_upper = topo(upper,y,x) - points(y,x)
         dist_lower = points(y,x) - topo(lower,y,x)

         val_upper = values(upper,y,x) * dist_lower
         val_lower = values(lower,y,x) * dist_upper

         valout(y,x) = (val_upper+val_lower)/(dist_upper+dist_lower)
        else
         valout(y,x) = values(minp,y,x)
        endif
       enddo
      enddo

      return
      END SUBROUTINE
