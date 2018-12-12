package br.com.kerubin.dsl.mkl.generator

import static extension br.com.kerubin.dsl.mkl.generator.EntityUtils.*
import static br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.model.Entity

class WebAppModuleTSGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		generateComponent
	}
	
	def generateComponent() {
		val path = webAppDir
		val filePath = path + toWebAppModuleName + '.ts'
		generateFile(filePath, generateAppComponent)
	}
	
	def CharSequence generateAppComponent() {
		'''
		import { ConfirmationService } from 'primeng/components/common/api';
		import { FormsModule } from '@angular/forms';
		import { BrowserModule } from '@angular/platform-browser';
		import {BrowserAnimationsModule} from '@angular/platform-browser/animations';
		import { NgModule, LOCALE_ID } from '@angular/core';
		import { AppComponent } from './app.component';
		import { HttpModule } from '@angular/http';
		
		import { registerLocaleData } from '@angular/common';
		import localePt from '@angular/common/locales/pt';
		import localeExtraPT from '@angular/common/locales/extra/pt';
		
		// PrimeNG
		import {InputTextModule} from 'primeng/inputtext';
		import {ButtonModule} from 'primeng/button';
		import {InputTextareaModule} from 'primeng/inputtextarea';
		import {CalendarModule} from 'primeng/calendar';
		import {TableModule} from 'primeng/table';
		import {TooltipModule} from 'primeng/tooltip';
		import {ToastModule} from 'primeng/toast';
		import {MessageService} from 'primeng/api';
		import {ConfirmDialogModule} from 'primeng/confirmdialog';
		import {AutoCompleteModule} from 'primeng/autocomplete';
		import {PanelModule} from 'primeng/panel';
		import {InputSwitchModule} from 'primeng/inputswitch';
		import {AccordionModule} from 'primeng/accordion';
		import {SpinnerModule} from 'primeng/spinner';
		import {SelectButtonModule} from 'primeng/selectbutton';
		import {DialogModule} from 'primeng/dialog';
		import {DropdownModule} from 'primeng/dropdown';
		
		// CurrencyMask
		import { CurrencyMaskModule } from 'ng2-currency-mask';
		import { CurrencyMaskConfig, CURRENCY_MASK_CONFIG } from 'ng2-currency-mask/src/currency-mask.config';
		
		// Rotas
		import { Routes, RouterModule } from '@angular/router';
		
		// Kerubin
		Begin Gerado
		«generateAppImports»
		End Gerado
		
		import { CadContaspagarComponent } from './contas/contaspagar/cad-contaspagar/cad-contaspagar.component';
		import { ListContaspagarComponent } from './contas/contaspagar/list-contaspagar/list-contaspagar.component';
		import { FornecedorService } from './contas/contaspagar/fornecedor.service';
		import { ContasPagarService } from './contas/contaspagar/contaspagar.service';
		
		registerLocaleData(localePt, 'pt', localeExtraPT);
		
		export const CustomCurrencyMaskConfig: CurrencyMaskConfig = {
		  align: 'right',
		  allowNegative: true,
		  decimal: ',',
		  precision: 2,
		  // prefix: 'R$ ',
		  prefix: '',
		  suffix: '',
		  thousands: '.'
		};
		
		«generateRoutes»
		const routes: Routes = [
		  { path: '', redirectTo: 'contaspagar', pathMatch: 'full' },
		  
		  { path: 'contaspagar/novo', component: CadContaspagarComponent },
		  { path: 'contaspagar/:id', component: CadContaspagarComponent },
		  
		  { path: 'contaspagar', component: ListContaspagarComponent }
		];
		
		
		
		@NgModule({
		  declarations: [
		    // Begin Gerado
		    «generateEntitiesNgModuleDeclarations»
		    // End Gerado
		    
		    CadContaspagarComponent,
		    ListContaspagarComponent,
		    AppComponent
		  ],
		  imports: [
		    RouterModule.forRoot(routes),
		    BrowserModule,
		    BrowserAnimationsModule,
		    FormsModule,
		    HttpModule,
		
		    CurrencyMaskModule,
		
		    // PrimeNG
		    InputTextModule,
		    ButtonModule,
		    InputTextareaModule,
		    CalendarModule,
		    TableModule,
		    TooltipModule,
		    ToastModule,
		    ConfirmDialogModule,
		    AutoCompleteModule,
		    PanelModule,
		    InputSwitchModule,
		    AccordionModule,
		    SpinnerModule,
		    SelectButtonModule,
		    DialogModule,
		    DropdownModule
		  ],
		  providers: [
		  	«generateEntitiesServiceProvidersDeclaration»
		    ContasPagarService,
		    FornecedorService,
		    MessageService,
		    ConfirmationService,
		    { provide: LOCALE_ID, useValue: 'pt' },
		    { provide: CURRENCY_MASK_CONFIG, useValue: CustomCurrencyMaskConfig }
		  ],
		  bootstrap: [AppComponent]
		})
		
		export class AppModule {
		
		}

		'''
	}
	
	def CharSequence generateEntitiesServiceProvidersDeclaration() {
		val source = entities.map[generateEntityServiceProviderDeclaration].join
		source
	}
	
	def CharSequence generateEntityServiceProviderDeclaration(Entity entity) {
		'''
		
		«entity.toEntityWebServiceClassName»,
		'''
	}
	
	def CharSequence generateEntitiesNgModuleDeclarations() {
		val source = entities.map[generateEntityNgModuleDeclarations].join
		source
	}
	
	def CharSequence generateEntityNgModuleDeclarations(Entity entity) {
		'''
		
		«entity.toEntityWebComponentClassName»,
		«entity.toEntityWebListClassName»,
		'''
	}
	
	def CharSequence generateRoutes() {
		val source = '''
		const routes: Routes = [
		  { path: '', redirectTo: 'mainmenu', pathMatch: 'full' },
		  
		  «generateAllEntityRoutes»
		  
		  { path: 'mainmenu', component: MainMenuComponent }
		];
		'''
		
		source
	}
	
	def CharSequence generateAllEntityRoutes() {
		val source = entities.map[generateEntityRoutes].join
		source
	}
	
	def CharSequence generateEntityRoutes(Entity entity) {
		val path = entity.webEntityPath
		val crudComponent = path + entity.toEntityWebComponentName
		val listComponent = path + entity.toEntityWebListComponentName
		
		val entityWebName = entity.toWebName
		
		'''
		
		{ path: '«entityWebName»/novo', component: «crudComponent» },
		{ path: '«entityWebName»/:id', component: «crudComponent» },
		{ path: '«entityWebName»/list', component: «listComponent» },
		'''
	}
	
	def CharSequence generateAppImports() {
		val source = entities.map[generateEntityAppImport].join
		source
	}
	
	def CharSequence generateEntityAppImport(Entity entity) {
		val path = entity.webEntityPath
		val crudComponent = path + entity.toEntityWebComponentName
		val listComponent = path + entity.toEntityWebListComponentName
		val serviceComponent = path + entity.toEntityWebServiceName
		
		'''
		
		import { «entity.toEntityWebComponentClassName» } from './«crudComponent»';
		import { «entity.toEntityWebListClassName» } from './«listComponent»';
		import { «entity.toEntityWebServiceClassName» } from './«serviceComponent»';
		'''
	}
	
}