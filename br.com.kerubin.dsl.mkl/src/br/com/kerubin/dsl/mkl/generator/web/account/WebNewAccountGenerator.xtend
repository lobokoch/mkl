package br.com.kerubin.dsl.mkl.generator.web.account

import static br.com.kerubin.dsl.mkl.generator.Utils.*
import br.com.kerubin.dsl.mkl.generator.GeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.IGeneratorExecutor
import br.com.kerubin.dsl.mkl.generator.BaseGenerator

class WebNewAccountGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	static val NEW_ACCOUNT = 'newccount'
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
		import { ActivatedRoute } from '@angular/router';
		import { LogoutService } from 'src/app/security/logout.service';
		import { AuthService } from './../../security/auth.service';
		import { Component, OnInit } from '@angular/core';
		import { UserAccountService } from '../useraccount.service';
		
		@Component({
		  selector: 'app-confirmaccount',
		  templateUrl: './confirmaccount.component.html',
		  styleUrls: ['./confirmaccount.component.css']
		})
		export class ConfirmAccountComponent implements OnInit {
		
		  connected = false;
		  btnLabel = 'Ir para página inicial';
		  confirmationAccountResult = '';
		  id = null;
		
		  constructor(
		    private userAccountService: UserAccountService,
		    private auth: AuthService,
		    private logout: LogoutService,
		    private route: ActivatedRoute
		  ) { }
		
		  ngOnInit() {
		    this.doLoginAnonymous();
		    this.id = this.route.snapshot.queryParams['id'];
		  }
		
		  confirmAccount(id: string) {
		    if (!id) {
		      console.log('Id inválido: ' + id);
		      this.confirmationAccountResult = 'O identificador da confirmação é inválido.';
		      this.logout.logout();
		      return;
		    }
		
		    this.userAccountService.confirmAccount(id)
		    .then((user) => {
		      this.btnLabel = 'Fazer login';
		      console.log('Account confirmation successed: ' + user);
		      this.confirmationAccountResult = `<h3>Parabéns <strong>${this.getFirstName(user.name)}</strong></h3>` +
		      '<p>Sua conta foi ativada com sucesso!</p>' +
		      '<p>Faça seu login para acessar o Kerubin.</p>';
		      this.logout.logout();
		    })
		    .catch((e) => {
		      console.log('Account confirmation error: '  + e);
		      this.confirmationAccountResult = '<h3>Ops :(</h3>' +
		        '<p>Ocorreu um erro na ativação da conta. Entre em contato com o serviço de suporte.</p>';
		      this.logout.logout();
		    });
		
		  }
		
		  private getFirstName(fullName: string): string {
		    if (!fullName) {
		      return fullName;
		    }
		    const result = fullName.substring(0, fullName.indexOf(' ')).trim();
		    return result;
		  }
		
		  private doLoginAnonymous() {
		    this.auth.doLoginAnonymous()
		    .then((result) => {
		      console.log('Anonymous connected!');
		      this.connected = true;
		      this.confirmAccount(this.id);
		    })
		    .catch((e) => {
		      this.connected = false;
		      console.log('Anonymous error: ' + e);
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