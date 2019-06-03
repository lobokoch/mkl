package br.com.kerubin.dsl.mkl.generator

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.model.Entity

class WebMenuGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	static val MENU_FILENAME_PREFIX = 'kerubin-menu'
	static val MENU_PREFIX = MENU_FILENAME_PREFIX + '.component'
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		generateMenuModule
		generateMenuComponentTS
		generateMenuComponentHTML
		generateMenuComponentCSS
	}
	
	def generateMenuModule() {
		val path = getWebMenuDir
		val filePath = path + MENU_FILENAME_PREFIX + '.module.ts'
		generateFile(filePath, doGenerateMenuModule)
	}
	
	def doGenerateMenuModule() {
		'''
		import { MenuModule } from 'primeng/menu';
		import { KerubinMenuComponent } from './kerubin-menu.component';
		import { PanelMenuModule } from 'primeng/panelmenu';
		import { NgModule } from '@angular/core';
		
		@NgModule({
		
		  imports: [
		    PanelMenuModule,
		    MenuModule
		  ],
		
		  declarations: [
		    KerubinMenuComponent
		  ],
		
		  exports: [
		    KerubinMenuComponent,
		    PanelMenuModule,
		    MenuModule
		  ]
		
		})
		
		export class KerubinMenuModule {  }
		
		'''
	}
	
	def generateMenuComponentHTML() {
		val path = getWebMenuDir
		val filePath = path + MENU_PREFIX + '.html'
		generateFile(filePath, doGenerateMenuComponentHTML)
	}
	
	def doGenerateMenuComponentHTML() {
		'''
		<p-panelMenu [model]="items"></p-panelMenu>
		
		'''
	}
	
	def generateMenuComponentCSS() {
		val path = getWebMenuDir
		val filePath = path + MENU_PREFIX + '.css'
		generateFile(filePath, doGenerateMenuComponentCSS)
	}
	
	def doGenerateMenuComponentCSS() {
		'''
		/* Your CSS heare */
		'''
	}
	
	def generateMenuComponentTS() {
		val path = getWebMenuDir
		val filePath = path + MENU_PREFIX + '.ts'
		generateFile(filePath, doGenerateMenuComponentTS)
	}
	
	def doGenerateMenuComponentTS() {
		'''
		import { Component, OnInit } from '@angular/core';
		import { MenuItem } from 'primeng/api';
		
		@Component({
		  selector: 'app-kerubin-menu',
		  templateUrl: './kerubin-menu.component.html',
		  styleUrls: ['./kerubin-menu.component.css']
		})
		export class KerubinMenuComponent implements OnInit {
		
		  items: MenuItem[];
		
		
		  constructor() { }
		
		  ngOnInit() {
		    this.loadMenu();
		  }
		
		  loadMenu() {
		    this.items = [
		
		      «doGenerateMenuItems»
		
		
		    ];
		  }
		
		}
		'''
	}
	
	protected def CharSequence doGenerateMenuItems() {
		service.domainModel
		val domainLabel = if (service.domainModel.hasLabel) service.domainModel.label else service.domain.toCamelCase
		val serviceLabel = if (service.hasLabel) service.label else service.name.toCamelCase
		
		'''
		{
			label: '«domainLabel»',
			icon: 'pi pi-pw',
			items: [
				
				{
					label: '«serviceLabel»',
					icon: 'pi pi-fw ',
					items: [
						«generateEntitiesMenuItems»
					]
				}
				
			]
		}
		'''
	}
	
	private def CharSequence generateEntitiesMenuItems() {
		'''
		«entities.filter[!it.externalEntity].map[generateEntityMenuItem].join(', \r\n')»
		'''
	}
	
	private def CharSequence generateEntityMenuItem(Entity entity) {
		'''{ label: '«entity.labelValue»', icon: 'pi pi-fw', routerLink: '/«entity.toWebName»' }'''
	}
	
	
}