package br.com.kerubin.dsl.mkl.generator.web.account

import static br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.generator.GeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.IGeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.BaseGenerator

class WebNewAccountGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	static val NEW_ACCOUNT = 'newaccount'
	static val USER_ACCOUNT_MODEL = 'useraccount.model'
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val path = getWebAccountDir + '/' + NEW_ACCOUNT 
		path.doGenerate
	}
	
	def doGenerate(String path) {
		val componentName = path + '/' + NEW_ACCOUNT + '.component'
		componentName.generateCSS
		componentName.generateHTML
		componentName.generateTS
		val userAccount = path + '/' + USER_ACCOUNT_MODEL
		userAccount.generateUserAccount
	}
	
	def generateUserAccount(String name) {
		val fileName = name + '.ts'
		generateFile(fileName, generateUserAccount)
	}
	
	def generateTS(String componentName) {
		val fileName = componentName + '.ts'
		generateFile(fileName, generateTSContent)
	}
	
	def CharSequence generateTSContent() {
		'''
		// Angular
		import { FormControl, FormGroup } from '@angular/forms';
		import { Component, OnInit } from '@angular/core';
		import { Router } from '@angular/router';
		
		// PrimeNG
		import { SelectItem } from 'primeng/api';
		
		// Kerubin
		import { AuthService } from './../../security/auth.service';
		import { UserAccountService } from '../useraccount.service';
		import { UserAccount, AccountCreatedDTO } from './useraccount.model';
		import { MessageHandlerService } from 'src/app/core/message-handler.service';
		import { LogoutService } from 'src/app/security/logout.service';
		
		@Component({
		  selector: 'app-newaccount',
		  templateUrl: './newaccount.component.html',
		  styleUrls: ['./newaccount.component.css']
		})
		export class NewAccountComponent implements OnInit {
		
		  userAccount = new UserAccount();
		  connected = false;
		  createdAccountResult = '';
		  accountCreated = false;
		  btnLabel = 'Criar conta';
		  disabled = false;
		  touched = false;
		
		  accountTypeSelected: SelectItem;
		  accountTypeFieldOptions: SelectItem[];
		
		  constructor(
		    private userAccountService: UserAccountService,
		    private messageHandler: MessageHandlerService,
		    private auth: AuthService,
		    private logout: LogoutService,
		    private router: Router
		  ) { }
		
		  ngOnInit() {
		    this.doLoginAnonymous();
		    this.accountTypeFieldOptions = [
		      { label: 'Conta pessoal, sou pessoa física', value: 'PERSONAL' },
		      { label: 'Conta organizacional, sou pessoa jurídica', value: 'CORPORATE' }
		    ];
		  }
		
		  validateAllFormFields(form: FormGroup) {
		    Object.keys(form.controls).forEach(field => {
		      const control = form.get(field);
		      if (control instanceof FormControl) {
		        control.markAsDirty({ onlySelf: true });
		      } else if (control instanceof FormGroup) {
		        this.validateAllFormFields(control);
		      }
		    });
		  }
		
		  createAccount(form: FormGroup) {
		    if (!form.valid) {
		      this.validateAllFormFields(form);
		      return;
		    }
		
		    this.disabled = true;
		    this.btnLabel = 'Criando a conta, aguarde...';
		    this.userAccount.accountType = this.accountTypeSelected.value;
		    this.userAccountService.createAccount(this.userAccount)
		      .then((response) => {
		        this.disabled = false;
		        this.btnLabel = 'Conta criada!';
		        this.createdAccountResult = response.text;
		        this.accountCreated = true;
		        this.logout.logout();
		      })
		      .catch((e) => {
		        console.log('Error at createAccount: ' + e);
		        this.disabled = false;
		        this.btnLabel = 'Erro!';
		
		        if (e.message && (e.message as string).toLowerCase().indexOf('http') === -1) {
		          this.createdAccountResult = '<h3>Ocorreu um erro.</h3><p>' + e.message + '</p>';
		        } else {
		          this.createdAccountResult = '<h3>Ops :(</h3>' +
		            '<p>Ocorreu um erro inesperado ao tentar criar a conta. Por favor tente novamente mais tarde.</p>';
		        }
		        this.accountCreated = true;
		        this.logout.logout();
		      });
		  }
		
		  private doLoginAnonymous() {
		    this.auth.doLoginAnonymous()
		      .then((result) => {
		        console.log('Anonymous connected!');
		        this.connected = true;
		      })
		      .catch((e) => {
		        this.connected = false;
		        this.messageHandler.showError(e);
		      });
		  }
		
		  goBack() {
		    this.logout.logout()
		      .then(() => {
		        this.router.navigate(['/login']);
		      })
		      .catch(() => {
		        this.router.navigate(['/login']);
		      });
		  }
		
		}		
		
		'''
	}
	
	def generateHTML(String componentName) {
		val fileName = componentName + '.html'
		generateFile(fileName, generateHTMLContent)
	}
	
	def CharSequence generateHTMLContent() {
		'''
		<div class="container" style="max-width: 400px; margin: auto">
		
		  <form *ngIf="!accountCreated" #form1="ngForm" (ngSubmit)="createAccount(form1.form)">
		    <div class="ui-g ui-fluid">
		
		      <div class="ui-g-12">
		        <div class="primeiro-mes-gratis">Aproveite, o primeiro mês <strong>é grátis.</strong></div>
		        <div class="criar-sua-conta">Crie sua conta.</div>
		      </div>
		
		      <div class="ui-g-12">
		          <div class="ui-inputgroup">
		              <span class="ui-inputgroup-addon"><i class="pi pi-pencil"></i></span>
		              <input appFocus [disabled]="disabled" pInputText type="text" placeholder="Nome completo" pInputText #name="ngModel" ngModel [(ngModel)]="userAccount.name" name="name" required>
		            </div>
		            <div class="invalid-message" *ngIf="name.invalid && name.dirty">Informe o nome completo.</div>
		      </div>
		
		      <div class="ui-g-12">
		          <div class="ui-inputgroup">
		              <span class="ui-inputgroup-addon"><i class="pi pi-user"></i></span>
		              <input [disabled]="disabled" pInputText type="email" placeholder="E-mail" #email="ngModel" ngModel [(ngModel)]="userAccount.email" name="email" required>
		            </div>
		            <div class="invalid-message" *ngIf="email.invalid && email.dirty">Informe o e-mail.</div>
		      </div>
		
		      <div class="ui-g-12">
		          <div class="ui-inputgroup">
		            <span class="ui-inputgroup-addon"><i class="pi pi-key"></i></span>
		            <input [disabled]="disabled" pInputText type="password" placeholder="Senha" #password="ngModel" ngModel [(ngModel)]="userAccount.password" name="password" required>
		          </div>
		          <div class="invalid-message" *ngIf="password.invalid && password.dirty">Informe a senha.</div>
		      </div>
		
		      <div class="ui-g-12">
		          <div class="ui-inputgroup">
		              <span class="newaccount-dropdown-icon ui-inputgroup-addon"><i class="pi pi-share-alt"></i></span>
		              <p-dropdown id="newaccount-dropdown" required #accountType="ngModel" ngModel
		              optionLabel="label" name="accountType" #accountType
		              [options]="accountTypeFieldOptions" [(ngModel)]="accountTypeSelected"
		              placeholder="Selecione o tipo da conta"></p-dropdown>
		            </div>
		            <div class="invalid-message" *ngIf="accountType.invalid && accountType.dirty">Selecione o tipo da conta.</div>
		      </div>
		
		      <div class="ui-g-12">
		        <button class="ui-button-raised ui-button-success" style="border: 1px solid darkgreen; font-weight: bold"  pButton [disabled]="disabled"  type="submit" [label]="btnLabel"></button>
		      </div>
		
		    </div>
		  </form>
		
		  <div *ngIf="accountCreated" class="ui-g ui-fluid">
		
		    <div class="ui-g-12">
		      <div [innerHTML]="createdAccountResult"></div>
		    </div>
		
		  </div>
		
		  <div class="ui-g-12 ui-fluid ui-md-3">
		    <a (click)="goBack()" *ngIf="!disabled" pButton style="border: 1px solid silver" class="ui-button-secondary" label="Voltar"></a>
		  </div>
		
		</div>
		
		'''
	}
	
	def generateCSS(String componentName) {
		val fileName = componentName + '.css'
		generateFile(fileName, generateCSSContent)
	}
	
	def CharSequence generateCSSContent() {
		'''
		/* CSS heare */ 
		'''
	}
	
	def CharSequence generateUserAccount() {
		'''
		
		export class SortField {
		  field: string;
		  order: number;
		
		  constructor(field: string, order: number) {
		    this.field = field;
		    this.order = order;
		  }
		}
		
		export class PaginationFilter {
		  pageNumber: number;
		  pageSize: number;
		  sortField: SortField;
		
		  constructor() {
		    this.pageNumber = 0;
		    this.pageSize = 10;
		  }
		}
		
		export class UserAccountListFilter extends PaginationFilter {
		
		}
		
		export class UserAccount {
			name: string;
			email: string;
			password: string;
			accountType: string;
		}
		
		export class UserAccountAutoComplete {
			name: string;
		}
		
		export class UserAccountSumFields {
		}
		
		export class AccountCreatedDTO {
			text: string;
		}
		
		export class SysUser {
		  id: string;
		  name: string;
		  email: string;
		  accountType: string;
		}
		
		'''
	}
	
	
}