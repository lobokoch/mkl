package br.com.kerubin.dsl.mkl.generator

import static br.com.kerubin.dsl.mkl.generator.Utils.*

class WebSecurityLoginGenerator extends GeneratorExecutor implements IGeneratorExecutor {
	
	
	new(BaseGenerator baseGenerator) {
		super(baseGenerator)
	}
	
	override generate() {
		generateFiles
	}
	
	def generateFiles() {
		val securityPath = getWebSecurityDir
		securityPath.generateLogin
	}
	
	def generateLogin(String securityPath) {
		val loginComponentName = securityPath + 'login/login.component'
		loginComponentName.generateLoginCSS
		loginComponentName.generateLoginHTML
		loginComponentName.generateLoginTS
	}
	
	def generateLoginTS(String loginComponentName) {
		val fileName = loginComponentName + '.ts'
		generateFile(fileName, generateLoginTSContent)
	}
	
	def CharSequence generateLoginTSContent() {
		'''
		import { FormGroup, FormControl } from '@angular/forms';
		import { Component, OnInit } from '@angular/core';
		import { Router } from '@angular/router';
		import { AuthService } from '../auth.service';
		import { MessageHandlerService } from 'src/app/core/message-handler.service';
		
		@Component({
		  selector: 'app-login',
		  templateUrl: './login.component.html',
		  styleUrls: ['./login.component.css']
		})
		
		export class LoginComponent implements OnInit {
		
		  btnLabel = 'Entrar';
		  username = '';
		  password = '';
		  autenticando = false;
		
		
		  constructor(
		    private auth: AuthService,
		    private messageHandler: MessageHandlerService,
		    private router: Router
		  ) { }
		
		  ngOnInit() {
		  }
		
		  login(form: FormGroup) {
		
		    if (!form.valid) {
		      this.validateAllFormFields(form);
		      return;
		    }
		
		    this.btnLabel = 'Autenticando...';
		    this.autenticando = true;
		
		    this.auth.login(this.username, this.password)
		      .then(() => {
		        const tenant = this.auth.tenant;
		        if (tenant) {
		          this.router.navigate(['/mainmenu']);
		        } else {
		          this.router.navigate(['/confignewaccount']);
		        }
		      })
		      .catch(error => {
		        this.password = '';
		        this.btnLabel = 'Entrar';
		        this.autenticando = false;
		        console.log('login error:' + error);
		        this.messageHandler.showError(error);
		      });
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
		
		}
		
		'''
	}
	
	def generateLoginHTML(String loginComponentName) {
		val fileName = loginComponentName + '.html'
		generateFile(fileName, generateLoginHTMLContent)
	}
	
	def CharSequence generateLoginHTMLContent() {
		'''
		<p-card class="centered">
		
		  <form #loginForm="ngForm">
		    <div class="ui-g ui-fluid">
		
		      <div class="ui-g-12 ui-fluid kerubin-logo">
		        <div class="ui-g-12 ui-fluid">
		          <div class="kerubin-logo"><img src="assets/images/logo2.png"></div>
		        </div>
		      </div>
		
		      <div class="ui-g-12 ui-fluid">
		        <div class="ui-g-12 ui-fluid">
		          <div class="ui-inputgroup">
		            <span class="ui-inputgroup-addon"><i class="pi pi-user"></i></span>
		            <input appFocus pInputText type="email"
		              #usernameLocal="ngModel" name="username" [(ngModel)]="username" placeholder="Seu e-mail" ngModel required>
		          </div>
		          <div style="display: block" class="invalid-message" *ngIf="usernameLocal.invalid && usernameLocal.dirty">
		            Informe seu usuário.</div>
		        </div>
		      </div>
		
		      <div class="ui-g-12 ui-fluid">
		        <div class="ui-g-12 ui-fluid">
		          <div class="ui-inputgroup">
		            <span class="ui-inputgroup-addon"><i class="pi pi-key"></i></span>
		            <input pInputText type="password"
		              #passwordLocal="ngModel" name="password" placeholder="Sua senha" [(ngModel)]="password" ngModel required>
		          </div>
		          <div style="display: block" class="invalid-message" *ngIf="passwordLocal.invalid && passwordLocal.dirty">
		            Informe sua senha.</div>
		        </div>
		      </div>
		
		      <div class="ui-g-12">
		        <div class="ui-g-12 ui-fluid">
		          <button [disabled]="autenticando" pButton style="font-weight: bold; border: 1px solid black; height: 120%"
		            type="submit" [label]="btnLabel" (click)="login(loginForm.form)">
		          </button>
		        </div>
		      </div>
		
		      <div class="ui-g-12">
		        <div class="ui-g-12 ui-fluid ui-md-6">
		          <a routerLink="/newaccount" pButton style="font-weight: bold; border: 1px solid darkgreen"
		            class="ui-button-success" label="Criar uma conta"></a>
		        </div>
		
		        <div class="ui-g-12 ui-fluid ui-md-6">
		          <a routerLink="/forgotpassword" pButton style="border: 1px solid silver" class="ui-button-secondary"
		            label="Esqueci a senha"></a>
		        </div>
		      </div>
		
		    </div>
		  </form>
		</p-card>

		
		'''
	}
	
	def generateLoginCSS(String loginComponentName) {
		val fileName = loginComponentName + '.css'
		generateFile(fileName, generateLoginCSSContent)
	}
	
	def CharSequence generateLoginCSSContent() {
		'''		
		.centered {
		  margin: 0px;
		  position: fixed;
		  top: 45%;
		  left: 50%;
		  /* bring your own prefixes */
		  transform: translate(-50%, -50%);
		  width: 400px;
		  border: 1px solid #eaeaea;
		  border-radius: 3px;
		}
		
		@media screen and (max-width: 399px) { /* < que 400*/
		  .centered {
		    width: 95%;
		  }
		}
		
		.kerubin-logo {
		  margin-top: 0px;
		  margin-bottom: 0px;
		  padding-top: 0px;
		  padding-bottom: 0px;
		  text-align: center;
		}
		
		/*section {
		  background-image:url('./img/bg2.jpg');
		  background-attachment:fixed;
		  background-repeat: no-repeat;
		  background-size: cover;
		}*/

		'''
	}
	
}