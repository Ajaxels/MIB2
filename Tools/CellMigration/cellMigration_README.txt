# Cell-Migration
https://se.mathworks.com/matlabcentral/fileexchange/67932-cell-migration-in-scratch-wound-assays
<h1>Analyse and measure migration in Scratch Wound Assays</h1>

<p>
This work was was accepted for publication in Electronics Letters:
</p>
<p>
Measuring cellular migration with image processing
CC Reyes-Aldasoro, D Biram, GM Tozer, C Kanthou

<a href="http://digital-library.theiet.org/content/journals/10.1049/el_20080943">

Electronics Letters</a> 44 (13), 791-793
</p>


![Screenshot](Figures/GraphicalDescription.jpg)

<h2>Input data with image of the cell population</h2>
        
<p>Input should be a matlab-readable image, the input can be a matlab matrix or the name of the file. For instance if the file "Example.tif" is in the matlab path, it can be read into matlab:
</p>
         
<pre class="codeinput">dataIn=imread(<span class="string">'Example.tif'</span>);
imagesc(dataIn);
colormap(gray)
</pre>

![Screenshot](Figures/cellMigrationDemo_01.png)




<p>Or it can be passed as a string</p><pre class="codeinput">dataIn=<span class="string">'Example.tif'</span>;
</pre><h2>Process the data with cellMigration<a name="3"></a></h2>
         <p>dataIn, either as a string or a matrix, is the only input parameter required for the algorithm of measurement of cell migration:</p><pre class="codeinput">[Res_stats,Res_colour,Res_gray]=cellMigrationAssay(dataIn);
</pre><h2>Output of the algorithm<a name="4"></a></h2>
         <p>The output arguments are the following: Res_stats, which will contain the minimum, average and maximum distances:</p><pre class="codeinput">disp(Res_stats)
</pre><pre class="codeoutput">    minimumDist: 268.0765
        maxDist: 416.9149
         avDist: 324.3023
           area: [2x1 double]

</pre><p>The area  covered by the wound is stored as number of pixels and as a relative to the total area of the image:</p><pre class="codeinput">disp(Res_stats.area(1))
disp(Res_stats.area(2))
</pre><pre class="codeoutput">      585570

    0.1911

</pre><p>The output images will display the original image with the boundaries overlaid:</p><pre class="codeinput">imagesc(Res_colour);

![Screenshot](Figures/cellMigrationDemo_02.png)

<br>
