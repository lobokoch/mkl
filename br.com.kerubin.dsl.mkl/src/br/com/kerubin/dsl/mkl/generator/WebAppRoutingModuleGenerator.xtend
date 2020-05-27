package br.com.kerubin.dsl.mkl.generator

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static extension br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.model.Entity

class WebAppRoutingModuleGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		generateAppRoutingModule
	}
	
	def generateAppRoutingModule() {
		val path = webAppDir
		val filePath = path + toWebAppRoutingModuleName + '.ts'
		generateFile(filePath, doGenerateAppRoutingModule)
	}
	
	def CharSequence doGenerateAppRoutingModule() {
		'''
		// Angular
		import { RouterModule, Routes } from '@angular/router';
		import { NgModule } from '@angular/core';
		
		// Kerubin - BEGIN
		import { ConfirmAccountComponent } from './account/confirmaccount/confirmaccount.component';
		import { NewAccountComponent } from './account/newaccount/newaccount.component';
		import { ConfigNewAccountComponent } from './account/confignewaccount/confignewaccount.component';
		import { LoginComponent } from './security/login/login.component';
		// Kerubin - END
		
		const routes: Routes = [
		  // ENTITY CHILD ROUTES
		  
		  «generateAllEntityRoutes»
		  
		  // *****
		  { path: 'mainmenu', loadChildren: './modules/cadastros/fornecedor/fornecedor/fornecedor.module#FornecedorModule' },
		  { path: '', redirectTo: 'login', pathMatch: 'full' },
		  
		  { path: 'login', component: LoginComponent },
		  { path: 'confignewaccount', component: ConfigNewAccountComponent },
		  { path: 'newaccount', component: NewAccountComponent },
		  { path: 'confirmaccount', component: ConfirmAccountComponent }
		];
		
		
		@NgModule({
		
		  imports: [
		    RouterModule.forRoot(routes)
		  ],
		
		  exports: [
		    RouterModule
		  ]
		
		})
		
		export class AppRoutingModule { }

		'''
	}
	
	def CharSequence generateAllEntityRoutes() {
		'''
		
		// BEGIN ENTITIES FOR SERVICE: «service.domain.webName».«service.name.webName»
		«entities.filter[isNotExternalEntity].map[generateEntityRoutes].join»
		// END ENTITIES FOR SERVICE: «service.domain».«service.name»
		
		'''
	}
	
	def CharSequence generateEntityRoutes(Entity entity) {
		val entityWebName = entity.toWebName
		
		'''
		{ path: '«entityWebName»',  loadChildren: () => import('./modules/«service.domain.webName»/«service.name.webName»/«entityWebName»/«entityWebName».module').then(m => m.«entity.toEntityWebModuleClassName») },
		'''
	}
	
	
}