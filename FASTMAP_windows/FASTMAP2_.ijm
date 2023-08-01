// FASTMAP
//
// Flexible Atlas Segmentation Tool for Multi-Area Processing
// V1.11
// Windows OS
// Copyright (C) 2021 Dylan Terstege - Epp Lab
//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details
//
// Your should have received a copy of the GNU General Public License
// along with this program. If not, see <https://www.gnu.org/licenses/>.
//
// Created 12-07-2019 Dylan Terstege
// Epp Lab, University of Calgary
// Contact: dylan.terstege@ucalgary.ca

path=getDirectory("Choose folder containing both image chanels");
list=getFileList(path);
platesubfold=getDirectory("Choose folder containing desired atlas plate ");
platelist=getFileList(platelist);

pathsplit=split(path,"\\");
index=pathsplit.length;
pathend=pathsplit[index-1];
platesubfoldsplit=split(platesubfold,"\\");
index=platesubfoldsplit.length;
platesubfoldend=platesubfoldsplit[index-1];

outplatepath=platesubfold+"RegisteredPlates";
File.makeDirectory(outplatepath);

Dialog.create("FASTMAP");
Dialog.addMessage("Processing files from directory:");
Dialog.addMessage(pathend);
Dialog.addMessage("Using plates from directory:");
Dialog.addMessage(platesubfoldend);
Dialog.addMessage("Please Identify Registration and Label Subfolders:");
Dialog.addChoice("Registration Subfolder",list);
Dialog.addChoice("Label Subfolder",list);
Dialog.show();

Autofolder=Dialog.getChoice;
autofile=path+Autofolder;
autolist=getFileList(autofile);
autocount=autolist.length;
Labelfolder=Dialog.getChoice;
labelfile=path+Labelfolder;
labellist=getFileList(labelfile);
Array.sort(labellist);
labelcount=labellist.length;

Dialog.create("FASTMAP");
Dialog.addMessage("The following directories have been selected:");
Dialog.addMessage(     "Registration Folder:");
Dialog.addMessage(Autofolder);
Dialog.addMessage("which contains this many images:");
Dialog.addMessage(autocount);
Dialog.addMessage(     "Label Folder:");
Dialog.addMessage(Labelfolder);
Dialog.addMessage("which contains this many images:");
Dialog.addMessage(labelcount);
Dialog.addMessage("Please Select Range");
Dialog.addNumber("Start at Image:", 1);
Dialog.addNumber("Stop at Image:", 1);
Dialog.addCheckbox("Volumetric Analysis", false);
Dialog.addCheckbox("Object Counts", false);
Dialog.addCheckbox("Intensity", false);
repeatOptions=newArray("No", "Yes");
Dialog.addChoice("Have image ROIs already been gathered?", repeatOptions);
Dialog.show();

startAt=Dialog.getNumber();
endAt=Dialog.getNumber();
vol=Dialog.getCheckbox();
objcount=Dialog.getCheckbox();
inten=Dialog.getCheckbox();
repeatType=Dialog.getChoice();

setBatchMode("show");
for (i=(startAt-1); i<(endAt); i++){

  open(autofile+autolist[i]);
  name=File.nameWithoutExtension;
  //Applying transformations to auto 
  tempdir=path+"temp\\";
  File.makeDirectory(tempdir);
  autotempfile=tempdir+"autotemp"+".tif";
  saveAs("tiff", autotempfile);
  close();
  open(labelfile+labellist[i]);
  labeltempfile=tempdir+"labeltemp"+".tif";
  saveAs("tiff", labeltempfile);
  close();
  

  //Picking registration
  //If images have yet to be analyzed
  if (repeatType == "No"){
  platesubfoldtif=platesubfoldend+".tif"; 
  open(platesubfold+platesubfoldtif);
  waitForUser("Move this image to the right of your screen then press 'OK'");
  corrScale = false;
  while (corrScale == false) {
  Dialog.create("Image Registration");
  Dialog.addMessage("2. Which of the plates most closely resembles your image?");
  open(autotempfile);
  setTool("rectangle");
  waitForUser("1. Draw a rectangle around the tissue section then press 'OK'");
  roiManager("Add");
  roiManager("Select", 0);
  Roi.getBounds(Lx,Ly,sectionw,sectionh);
  roiManager("Select", 0);
  roiManager("Deselect");
  roiManager("Delete");
  Dialog.addNumber("Plate number:", 1);
  Dialog.show();
  plateNum=Dialog.getNumber;
  close();
  close();
  Dialog.create("Is ROI correct?");
  Dialog.addCheckbox("Check if ROI matches and is scaled properly:", true);
  Dialog.show();
  corrScale = Dialog.getCheckbox();
  }
 
  //Applying plate to the image
  open(autotempfile);
  //setBatchMode(true);
  getDimensions(imh,imw,chan,sli,fra);
  ROIname="RoiSet_"+plateNum+".zip";
  ROIfile=platesubfold+ROIname;
  roiManager("Open", ROIfile);
  roinum=roiManager("count");
  roiManager("deselect");
  roiManager("combine");
  roiManager("add");
  roiManager("select",(roinum));
  Roi.getBounds(x, y, roiw, roih);
  roiManager("select",roinum);
  roiManager("Delete");
  xscale=(sectionw/roiw);
  yscale=(sectionh/roih);
  midpointx=roiw/2;
  midpointy=roih/2;
  midimx=imw/2;
  midimy=imh/2;
  transy=midimx-midpointx;
  transx=midimy-midpointy;
  setBatchMode("show");
  roiManager("Show All");
  for(trans = 0; trans < roinum; trans++){
    roiManager("select", trans);
    roiManager("translate", transx, transy);}
  roiManager("combine");
  roiManager("add");
  roiManager("select",(roinum));
  Roi.getBounds(Tx, Ty, roiw, roih);
  roiManager("select",roinum);
  roiManager("Delete");
  roiManager("select",0);
  Roi.getBounds(x1, y1, roiIw, roiIh);
  run("Scale... ", "x=xscale y=yscale centered");
  roiManager("Update");
  Roi.getBounds(CurrX, CurrY, Currw, Currh);
  roiManager("translate", (xscale*(x1-Tx)+midimx-CurrX), (yscale*(y1-Ty)+midimy-CurrY));
  roiManager("select", 0);
  Roi.getBounds(x2, y2, Currw, Currh);
  waitForUser("Move and adjust " + Roi.getName);
  roiManager("Update");
  Roi.getBounds(x3, y3, roiIw, roiIh);
  userShiftx = midimx + x3 - x2;
  userShifty = midimy + y3 - y2;
  for(scl = 1; scl <roinum; scl++){
    roiManager("select",scl);
    Roi.getBounds(Ix, Iy, roiIw, roiIh);
    run("Scale... ", "x=xscale y=yscale centered");
    roiManager("Update");
    Roi.getBounds(CurrX, CurrY, Currw, Currh);
    autoDx = (xscale*(Ix-Tx)+userShiftx-CurrX);
    autoDy = (yscale*(Iy-Ty)+userShifty-CurrY);
    roiManager("translate", autoDx, autoDy);}
  Dialog.create("Skip Others?");
  Dialog.addCheckbox("skip others?", false);
  Dialog.show();
  skipOthers = Dialog.getCheckbox();
  if (skipOthers == false) {
  for(final=1; final<roinum; final++){
    roiManager("select",final);
    waitForUser("Move and adjust " + Roi.getName);
    roiManager("Update");}}
  outname=outplatepath+"/"+name+".zip";
  roiManager("save", outname);
  roiManager("select",0);
  roiManager("Update");
  close();
  open(labeltempfile);}
    
  //If images have previously been analyzed
  if (repeatType == "Yes"){
  open(autotempfile);
  makeOval(2, 2, 2, 2);
  roiManager("add");
  roiManager("select",0);
  roiManager("Delete");
  waitForUser("'More', 'Open', find appropriate ROI set. Click 'OK' once complete");
  roiManager("Show All");
  waitForUser("Adjust if needed, click 'OK' when complete");
  roiManager("select",0);
  roiManager("Update");
  close();
  open(labeltempfile);} 
  
  //Apply the process that you'd like to measure

  if (vol){
    saveFileName="VolumetricAnalysis.csv";
    run("8-bit");
    listROI=roiManager("count");
    //setAutoThreshold("Default dark");
    //run("Convert to Mask");
    run("Set Measurements...", "area area_fraction limit display  redirect=None decimal=4");
    roiManager("select", 0);
    rName=Roi.getName();
    run("Set Measurements...", "area area_fraction display redirect=None decimal=4");
    roiManager("Measure");
    totalArea=getResult("Area",0);
    percentLabel=getResult("%Area",0);
    labelArea=totalArea*(percentLabel/100);
    close("Results");

    if (isOpen("R1")){
      selectWindow("R1");
      IJ.renameResults("R1","Results");
      numAlreadyIn=nResults;
      setResult("Region", 0+numAlreadyIn, rName);
      setResult("Region Area", 0+numAlreadyIn, totalArea);
      setResult("Label Area", 0+numAlreadyIn, labelArea);
      setResult("%Labeled", 0+numAlreadyIn, percentLabel);
      IJ.renameResults("Results","R1");
      for(j = 1; j < listROI; j++){
        roiManager("select", j);
        rName=Roi.getName();
        run("Set Measurements...", "area area_fraction display redirect=None decimal=4");
        roiManager("Measure");
        totalArea=getResult("Area",0);
        percentLabel=getResult("%Area",0);
        labelArea=totalArea*(percentLabel/100);
        close("Results");
        selectWindow("R1");
        IJ.renameResults("R1","Results");
        setResult("Region", j+numAlreadyIn, rName);
        setResult("Region Area", j+numAlreadyIn, totalArea);
        setResult("Label Area", j+numAlreadyIn, labelArea);
        setResult("%Labeled", j+numAlreadyIn, percentLabel);
        updateResults;
        IJ.renameResults("Results","R1");
      } //for (j = 1; j < listROI; j++)
    } //if (isOpen("R1"))
    else{
      setResult("Region", 0, rName);
      setResult("Region Area", 0, totalArea);
      setResult("Label Area", 0, labelArea);
      setResult("%Labeled", 0, percentLabel);
      IJ.renameResults("Results","R1");
      for(j = 1; j < listROI; j++){
        roiManager("select", j);
        rName=Roi.getName();
        run("Set Measurements...", "area area_fraction display redirect=None decimal=4");
        roiManager("Measure");
        totalArea=getResult("Area",0);
        percentLabel=getResult("%Area",0);
        labelArea=totalArea*(percentLabel/100);
        close("Results");
        selectWindow("R1");
        IJ.renameResults("R1","Results");
        setResult("Region", j, rName);
        setResult("Region Area", j, totalArea);
        setResult("Label Area", j, labelArea);
        setResult("%Labeled", j, percentLabel);
        updateResults;
        IJ.renameResults("Results","R1");

      } //for(j = 1; j < listROI; j++)
    } //else

    roiManager("Reset");
    close();}

  else if (objcount){
    saveFileName="RegionalCounts.csv";
    run("8-bit");
    setAutoThreshold("Default dark");
    run("Set Measurements...", "area area_fraction display redirect=None decimal=4");
    listROI=roiManager("count");
    roiManager("select", 0);
    rName=Roi.getName();
    run("Measure");
    regionArea=getResult("Area", 0);
    close("Results");
    run("Analyze Particles...", "pixel summarize");
    selectWindow("Summary");
    IJ.renameResults("Summary","Results");
    cellCount=getResult("Count", 0);
    close("Results");
    normalized=cellCount/regionArea;
    if (isOpen("R1")){ 
    selectWindow("R1");
    IJ.renameResults("R1","Results");
    numAlreadyIn=nResults;
    setResult("Region", 0+numAlreadyIn, rName);
    setResult("Point Count", 0+numAlreadyIn, cellCount);
    setResult("Region Area", 0+numAlreadyIn, regionArea);
    IJ.renameResults("Results","R1");
    for(j = 1; j < listROI; j++){
      roiManager("select", j);
      rName=Roi.getName();
      run("Set Measurements...", "area area_fraction display redirect=None decimal=4");
      run("Measure");
      regionArea=getResult("Area", 0);
      close("Results");
      run("Analyze Particles...", "pixel summarize");
      selectWindow("Summary");
      IJ.renameResults("Summary","Results");
      cellCount=getResult("Count", 0);
      close("Results");
      selectWindow("R1");
      IJ.renameResults("R1","Results");
      normalized=cellCount/regionArea;
      setResult("Region", j+numAlreadyIn, rName);
      setResult("Point Count", j+numAlreadyIn, cellCount);
      setResult("Region Area", j+numAlreadyIn, regionArea);
      updateResults;
      IJ.renameResults("Results","R1");
      }
    }

    else{
    setResult("Region", 0, rName);
    setResult("Point Count", 0, cellCount);
    setResult("Region Area", 0, regionArea);
    IJ.renameResults("Results","R1");
    for(j = 1; j < listROI; j++){
      roiManager("select", j);
      rName=Roi.getName();
      run("Set Measurements...", "area area_fraction display redirect=None decimal=4");
      run("Measure");
      regionArea=getResult("Area", 0);
      close("Results");
      run("Analyze Particles...", "pixel summarize");
      selectWindow("Summary");
      IJ.renameResults("Summary","Results");
      cellCount=getResult("Count", 0);
      close("Results");
      selectWindow("R1");
      IJ.renameResults("R1","Results");
      normalized=cellCount/regionArea;
      setResult("Region", j, rName);
      setResult("Point Count", j, cellCount);
      setResult("Region Area", j, regionArea);
      updateResults;
      IJ.renameResults("Results","R1");
      }}
    roiManager("Reset");
    close();
}
}
if (inten) {
    saveFileName="RegionalIntensities.csv";
    run("8-bit");
    setAutoThreshold("Default dark");
    run("Set Measurements...", "area mean min integrated area_fraction redirect=None decimal=4");
    listROI=roiManager("count");
    roiManager("select", 0);
    rName=Roi.getName();
    roiManager("Measure");
    regionArea=getResult("Area", 0);
    intDens=getResult("IntDen", 0);
    avgGray=getResult("Mean", 0);
    minGray=getResult("Min", 0);
    maxGray=getResult("Max",0);
    close("Results");
    
    if (isOpen("R1")) {
      selectWindow("R1");
      IJ.renameResults("R1","Results");
      numAlreadyIn=nResults;
      setResult("Region", 0 + numAlreadyIn, rName);
      setResult("Region Area", 0 + numAlreadyIn, regionArea);
      setResult("Integrated Density", 0+numAlreadyIn, intDens);
      setResult("Mean Gray Value", 0+numAlreadyIn, avgGray);
      setResult("Min Gray Value", 0+numAlreadyIn, minGray);
      setResult("Max Gray Value", 0+numAlreadyIn, maxGray);
      IJ.renameResults("Results","R1");
      for(j=1; j < listROI; j++) {
        oiManager("select", j);
        rName=Roi.getName();
        run("Set Measurements...", "area mean min integrated area_fraction redirect=None decimal=4");
        roiManager("Measure");
        regionArea=getResult("Area", 0);
        intDens=getResult("IntDen", 0);
        avgGray=getResult("Mean", 0);
        minGray=getResult("Min", 0);
        maxGray=getResult("Max",0);
        close("Results");
        selectWindow("R1");
        IJ.renameResults("R1","Results");
        numAlreadyIn=nResults;
        setResult("Region", j + numAlreadyIn, rName);
        setResult("Region Area", j + numAlreadyIn, regionArea);
        setResult("Integrated Density", j+numAlreadyIn, intDens);
        setResult("Mean Gray Value", j+numAlreadyIn, avgGray);
        setResult("Min Gray Value", j+numAlreadyIn, minGray);
        setResult("Max Gray Value", j+numAlreadyIn, maxGray);
        updateResults;
        IJ.renameResults("Results","R1");
      }
    }
    else { 
      setResult("Region", 0, rName);
      setResult("Region Area", 0, regionArea);
      setResult("Integrated Density", 0, intDens);
      setResult("Mean Gray Value", 0, avgGray);
      setResult("Min Gray Value", 0, minGray);
      setResult("Max Gray Value", 0, maxGray);
      IJ.renameResults("Results","R1");
      for(j=1; j < listROI; j++) {
        roiManager("select", j);
        rName=Roi.getName();
        run("Set Measurements...", "area mean min integrated area_fraction redirect=None decimal=4");
        roiManager("Measure");
        regionArea=getResult("Area", 0);
        intDens=getResult("IntDen", 0);
        avgGray=getResult("Mean", 0);
        minGray=getResult("Min", 0);
        maxGray=getResult("Max",0);
        close("Results");
        selectWindow("R1");
        IJ.renameResults("R1","Results");
        numAlreadyIn=nResults;
        setResult("Region", j, rName);
        setResult("Region Area", j, regionArea);
        setResult("Integrated Density", j, intDens);
        setResult("Mean Gray Value", j, avgGray);
        setResult("Min Gray Value", j, minGray);
        setResult("Max Gray Value", j, maxGray);
        updateResults;
        IJ.renameResults("Results","R1");
      }
    }
    roiManager("Reset");
    close();
}
IJ.renameResults("R1","Results");
saveAs("Results",path+saveFileName);
close("Results");
close("ROI Manager");
waitForUser("Dataset Complete"); 
