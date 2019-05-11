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
		import { HttpClientModule } from '@angular/common/http';
		
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
		import {CardModule} from 'primeng/card';
		
		
		// CurrencyMask
		import { CurrencyMaskModule } from 'ng2-currency-mask';
		import { CurrencyMaskConfig, CURRENCY_MASK_CONFIG } from 'ng2-currency-mask/src/currency-mask.config';
		
		// Rotas
		import { Routes, RouterModule } from '@angular/router';
		import { AuthGuard } from './security/auth.guard';
		
		// Kerubin begin
		«generateAppImports»
		
		import { NavbarComponent } from './navbar/navbar.component';
		import { LoginComponent } from './security/login/login.component';
		import { SecurityModule } from './security/security.module';
		import { CoreModule } from './core/core.module';
		import { NewAccountComponent } from './account/newaccount/newaccount.component';
		import { ConfirmAccountComponent } from './account/confirmaccount/confirmaccount.component';
		import { ConfigNewAccountComponent } from './account/confignewaccount/confignewaccount.component';
		import { UserAccountService } from './account/useraccount.service';
		import { FocusDirective } from './directive/focus.directive';
		
		// Kerubin end
		
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
		
		const routes: Routes = [
		  { path: '', redirectTo: 'login', pathMatch: 'full' },
		  
			// Kerubin Begin
			«generateRoutes»
			// Kerubin Begin
		  
		  { path: 'mainmenu', component: ContaPagarListComponent, canActivate: [AuthGuard] },
		  { path: 'login', component: LoginComponent },
		  { path: 'confignewaccount', component: ConfigNewAccountComponent },
		  { path: 'newaccount', component: NewAccountComponent },
		  { path: 'confirmaccount', component: ConfirmAccountComponent }
		];
		
		
		
		@NgModule({
		  declarations: [
		    // Kerubin Begin
		    «generateEntitiesNgModuleDeclarations»
		    «toWebNavbarClassName»,
		    LoginComponent,
		    NewAccountComponent,
		    ConfirmAccountComponent,
		    ConfigNewAccountComponent,
		    FocusDirective,
		    // Kerubin End
		    
		    AppComponent
		  ],
		  imports: [
		    RouterModule.forRoot(routes),
		    BrowserModule,
		    BrowserAnimationsModule,
		    FormsModule,
		    HttpClientModule,
		
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
		    DropdownModule,
		    CardModule,
		    
		    CoreModule,
		    SecurityModule
		  ],
		  providers: [
		  	// Kerubin Begin
		  	«generateEntitiesServiceProvidersDeclaration»
		  	«service.toTranslationServiceClassName»,
		  	UserAccountService,
		  	// Kerubin End
		  	
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
		  «generateAllEntityRoutes»
		'''
		
		source
	}
	
	def CharSequence generateAllEntityRoutes() {
		val source = entities.map[generateEntityRoutes].join
		source
	}
	
	def CharSequence generateEntityRoutes(Entity entity) {
		val crudComponent = entity.toEntityWebComponentClassName
		val listComponent = entity.toEntityWebListClassName
		
		val entityWebName = entity.toWebName
		
		'''
		
		{ path: '«entityWebName»/novo', component: «crudComponent», canActivate: [AuthGuard] },
		{ path: '«entityWebName»/:id', component: «crudComponent», canActivate: [AuthGuard] },
		{ path: '«entityWebName»', component: «listComponent», canActivate: [AuthGuard] },
		'''
	}
	
	def CharSequence generateAppImports() {
		val source = entities.map[generateEntityAppImport].join
		
		'''
		«source»
		import { «service.toTranslationServiceClassName» } from '«service.serviceWebTranslationPathName»';
		'''
	}
	
	def CharSequence generateEntityAppImport(Entity entity) {
		val path = entity.webEntityPathShort
		val crudComponent = path + entity.toEntityWebCRUDComponentName
		val listComponent = path + entity.toEntityWebListComponentName
		val serviceComponent = path + entity.toEntityWebServiceName
		
		'''
		
		import { «entity.toEntityWebComponentClassName» } from './«crudComponent»';
		import { «entity.toEntityWebListClassName» } from './«listComponent»';
		import { «entity.toEntityWebServiceClassName» } from './«serviceComponent»';
		'''
	}
	
}