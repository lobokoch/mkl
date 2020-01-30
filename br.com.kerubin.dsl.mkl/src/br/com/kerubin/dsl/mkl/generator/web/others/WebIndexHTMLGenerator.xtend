package br.com.kerubin.dsl.mkl.generator.web.others

import static br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.generator.GeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.IGeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.BaseGenerator

class WebIndexHTMLGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val path = getWebSrcDir
		path.generateFiles
	}
	
	def generateFiles(String path) {
		val fileName = path + '/index.html'
		generateFile(fileName, generateContent)
	}
	
	def CharSequence generateContent() {
		val hasWebAnalitycs = service.hasWebAnalitycs
		
		'''
		<!doctype html>
		<html lang="en">
		
		<head>
		  «IF hasWebAnalitycs»
		  
		  <!-- Global site tag (gtag.js) - Google Analytics -->
		  <script async src="https://www.googletagmanager.com/gtag/js?id=UA-157001792-1"></script>
		  <script>
		    window.dataLayer = window.dataLayer || [];
		    function gtag() { dataLayer.push(arguments); }
		    gtag('js', new Date());
		    // gtag('config', 'UA-157001792-1');
		  </script>
		  
		  «ENDIF»
		  <!--<meta charset="utf-8">-->
		  <title>Kerubin</title>
		  <base href="/">
		
		  <meta name="viewport" content="width=device-width, initial-scale=1">
		  <link rel="icon" type="image/x-icon" href="favicon.ico">
		</head>
		
		<body>
		  <app-root></app-root>
		</body>
		
		</html>
		'''
	}
	
}