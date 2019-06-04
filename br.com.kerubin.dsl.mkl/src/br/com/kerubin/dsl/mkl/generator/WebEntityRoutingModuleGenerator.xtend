package br.com.kerubin.dsl.mkl.generator

import br.com.kerubin.dsl.mkl.model.Entity

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*

class WebEntityRoutingModuleGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		entities.forEach[generateRoutingModule]
	}
	
	def generateRoutingModule(Entity entity) {
		val path = entity.webEntityPath
		val entityFile = path + entity.toEntityWebRoutingModuleName + '.ts'
		generateFile(entityFile, entity.doGenerate)
	}
	
	def CharSequence doGenerate(Entity entity) {
		val entityName = entity.toDtoName
		val entityWebName = entity.toWebName
		
		'''
		import { «entityName»Component } from './crud-«entityWebName».component';
		import { AuthGuard } from '../../../../security/auth.guard';
		import { «entityName»ListComponent } from './list-«entityWebName».component';
		import { RouterModule, Routes } from '@angular/router';
		import { NgModule } from '@angular/core';
		
		const routes: Routes = [
		  // Must add in forRoot
		  // { path: '«entityWebName»', loadChildren: './modules/«service.domain»/«service.name»/«entityWebName»/«entityWebName».module#«entity.toEntityWebModuleClassName»' }
		  {
		    path: '',
		    component: «entityName»ListComponent,
		    canActivate: [AuthGuard]
		  },
		  {
		    path: 'novo',
		    component: «entityName»Component,
		    canActivate: [AuthGuard]
		  },
		  {
		    path: ':id',
		    component: «entityName»Component,
		    canActivate: [AuthGuard]
		  }
		];
		
		
		@NgModule({
		
		  imports: [
		    RouterModule.forChild(routes)
		  ],
		
		  exports: [
		    RouterModule
		  ]
		
		})
		
		export class «entity.toEntityWebRoutingModuleClassName» { }
		'''		
		
	}
	
	
	
	
	
	
	
}