package br.com.kerubin.dsl.mkl.generator.web.diretive

import static br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.generator.GeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.IGeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.BaseGenerator

class WebFocusDirectiveGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val path = getWebDirectiveDir
		path.generateFiles
	}
	
	def generateFiles(String path) {
		val name = path + 'focus.directive'
		name.doGenerate
	}
	
	def doGenerate(String name) {
		val fileName = name + '.ts'
		generateFile(fileName, generateContent)
	}
	
	def CharSequence generateContent() {
		'''
		import { NgZone, Directive, AfterContentInit, ElementRef, Renderer2 } from '@angular/core';
		
		@Directive({
		  selector: '[appFocus]'
		})
		export class FocusDirective implements AfterContentInit {
		
		  constructor(
		    private el: ElementRef,
		    private zone: NgZone,
		    private renderer: Renderer2) {}
		
		  ngAfterContentInit(): void {
		    this.zone.runOutsideAngular(() => setTimeout(() => {
		            this.renderer.selectRootElement(this.el.nativeElement).focus();
		        }, 0));
		  }
		
		}
		'''
	}
	
}